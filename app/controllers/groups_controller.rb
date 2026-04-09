# Controller CRUD per i gruppi e le azioni di partecipazione.
# I gruppi sono comunità con ruoli, proposte interne, blog, forum ed eventi.
#
# Flusso di partecipazione:
# - `ask_for_participation` → crea una `GroupParticipationRequest` (status 1 = in attesa)
# - `participation_request_confirm` → accetta (status 3) o manda a votazione (status 2)
# - `participation_request_decline` → rifiuta (status 4) o manda a votazione (status 2)
# Il comportamento dipende da `group.request_by_portavoce?` (accettazione automatica vs votazione).
class GroupsController < ApplicationController
  layout :choose_layout

  before_action :authenticate_user!, except: %i[index show by_year_and_month]

  before_action :load_group, except: %i[index new create ask_for_multiple_follow]

  load_resource

  # `participation_request_confirm/decline` gestiscono la propria autorizzazione internamente
  # perché richiedono CanCan `:accept_requests` su @group, non il permesso CRUD standard.
  authorize_resource except: %i[participation_request_confirm participation_request_decline]

  before_action :admin_required, only: [:autocomplete]

  def autocomplete
    groups = Group.autocomplete(params[:term])
    groups = groups.map do |u|
      { id: u.id, identifier: u.name.to_s, image_path: (u.group_image_tag 20).to_s }
    end
    render json: groups
  end

  def index
    @tags = Tag.most_groups(current_domain.territory, 10).shuffle unless request.xhr?

    params[:interest_border] ||= InterestBorder.to_key(current_domain.territory)

    @pagy, @groups = pagy(Group.look(params), items: 30)
    respond_to do |format|
      format.html
      format.turbo_stream do
        @disable_per_page = true
      end
    end
  end

  # Pagina principale del gruppo con blog posts, ultimi topic forum ed eventi futuri.
  # Il redirect 301 forza la URL canonica (friendly_id può avere slug multipli dopo rename).
  def show
    @group_posts = @group.post_publishings.
                   accessible_by(current_ability).
                   order('post_publishings.featured desc, blog_posts.published_at DESC, blog_posts.created_at DESC')

    respond_to do |format|
      format.html do
        # Canonical URL enforcement: friendly_id mantiene gli slug vecchi come redirect.
        # Senza questo check, lo stesso gruppo sarebbe raggiungibile via slug vecchio e nuovo.
        if request.url.split('?')[0] != group_url(@group).split('?')[0]
          redirect_to group_url(@group), status: :moved_permanently
          return
        end
        @page_title = @group.name
        @pagy, @group_posts = pagy(@group_posts, items: COMMENTS_PER_PAGE)
        load_page_data
      end
      format.turbo_stream do
        @pagy, @group_posts = pagy(@group_posts, items: COMMENTS_PER_PAGE)
      end
      format.atom
      format.json
    end
  end

  def by_year_and_month
    @group_posts = @group.post_publishings.
                   accessible_by(current_ability).
                   where(' extract(year from blog_posts.created_at) = ? AND extract(month from blog_posts.created_at) = ? ', params[:year], params[:month]).
                   order('post_publishings.featured desc, published_at DESC').
                   select('post_publishings.*, published_at').
                   distinct
    @pagy, @group_posts = pagy(@group_posts, items: COMMENTS_PER_PAGE)

    respond_to do |format|
      format.html do
        @page_title = t('pages.groups.archives.title', group: @group.name, year: params[:year], month: t('calendar.monthNames')[params[:month].to_i - 1])
        load_page_data
        render 'show'
      end
      format.turbo_stream do
        render 'show'
      end
      format.json { render 'show' }
    end
  end

  # Carica i dati laterali comuni a `show` e `by_year_and_month`.
  # `accessible_by(current_ability, false)` — il secondo argomento `false` disabilita la sanitizzazione
  # per permettere la query GROUP BY (la sanitizzazione standard di CanCan non è compatibile con aggregazioni).
  def load_page_data
    @group_participations = @group.participants
    @archives = @group.blog_posts.
                accessible_by(current_ability, false).
                select('COUNT(*) AS posts, extract(month from blog_posts.created_at) AS MONTH, extract(year from blog_posts.created_at) AS YEAR').
                group('MONTH, YEAR').
                order(Arel.sql('YEAR desc, extract(month from blog_posts.created_at) desc'))

    @last_topics = @group.topics.
                   accessible_by(Ability.new(current_user)).
                   includes(:views, :forum).order('frm_topics.created_at desc').limit(10)
    @next_events = @group.events.
                   accessible_by(Ability.new(current_user)).next.
                   order('starttime asc').limit(4)
    @next_events_count = @group.next_events.count
  end

  def new
    authorize! :create, Group
    @group = Group.new(accept_requests: 'p')
    @group.default_role_actions = DEFAULT_GROUP_ACTIONS
  end

  def edit
    authorize! :update, @group
    @page_title = t('pages.groups.edit.title')
  end

  def create
    @group.current_user_id = current_user.id
    if @group.save
      respond_to do |format|
        flash[:notice] = t('info.groups.group_created')
        format.html { redirect_to group_url(@group) }
      end
    else
      respond_to do |format|
        format.html { render :new }
        format.turbo_stream { render partial: 'layouts/flash_stream', status: :unprocessable_entity }
      end
    end
  end

  def update
    if @group.update(group_params)
      flash[:notice] = t('info.groups.group_updated')
      redirect_to edit_group_url @group
    else
      flash[:error] = t('error.groups.update')
      render action: ' edit '
    end
  end

  def destroy
    authorize! :destroy, @group
    @group.destroy
    flash[:notice] = t('info.groups.group_deleted')

    respond_to do |format|
      format.html { redirect_to(groups_url) }
    end
  end

  # Invia una richiesta di partecipazione al gruppo.
  # Stati della GroupParticipationRequest:
  #   1 = in attesa (pendente)
  #   2 = in votazione (il gruppo vota l'ammissione)
  #   3 = accettata
  #   4 = rifiutata
  #
  # Caso speciale: se l'utente è già membro (partecipazione senza richiesta nel DB),
  # crea una richiesta di correzione con status 3 per allineare i dati.
  def ask_for_participation
    request = current_user.group_participation_requests.find_by(group_id: @group.id)
    if request
      flash[:notice] = t('info.group_participations.request_alredy_sent')
    else
      participation = @group.participants.include? current_user
      if participation
        # Correzione dati: l'utente è già membro ma manca la richiesta nel DB
        request = GroupParticipationRequest.new
        request.user_id = current_user.id
        request.group_id = @group.id
        request.group_participation_request_status_id = 3
        saved = request.save
        if saved
          flash[:error] = t('error.group_participations.request_not_registered')
        else
          flash[:notice] = t('error.group_participations.already_member')
        end
      else
        request = GroupParticipationRequest.new
        request.user_id = current_user.id
        request.group_id = @group.id
        request.group_participation_request_status_id = 1
        saved = request.save
        if saved
          flash[:notice] = t('info.group_participations.request_sent')
        else
          flash[:error] = t('error.group_participations.request_sent')
        end
      end
    end
    redirect_to_back(group_path(@group))
  end

  # Invia richieste di partecipazione multiple (onboarding wizard, step "seguire gruppi consigliati").
  # Gli ID dei gruppi arrivano come stringa separata da `;` dal form JS.
  # Usa transazione: se una richiesta fallisce, nessuna viene salvata.
  def ask_for_multiple_follow
    Group.transaction do
      groups = params[:groupsi][:group_ids].split(';')
      number = 0
      groups.each do |group_id|
        group = Group.find(group_id)
        request = current_user.group_participation_requests.find_by(group_id: group.id)
        next if request

        participation = current_user.groups.find_by(id: group.id)
        if participation # verifica se per caso non fa già parte del gruppo
          # crea una nuova richiesta di partecipazione ACCETTATA per correggere i dati
          request = GroupParticipationRequest.new
          request.user_id = current_user.id
          request.group_id = group.id
          request.group_participation_request_status_id = 3 # accettata, dati corretti
          request.save!
        else
          # inoltra la richiesta di partecipazione con stato IN ATTESA
          request = GroupParticipationRequest.new
          request.user_id = current_user.id
          request.group_id = group.id
          request.group_participation_request_status_id = 1 # in attesa...
          request.save!
          number += 1
        end
      end
      flash[:notice] = t('info.participation_request.multiple_request', count: number)
      redirect_to home_path
    end
  end

  # Conferma una richiesta di partecipazione pendente.
  # Se il gruppo accetta per decisione del portavoce (`request_by_portavoce?`):
  #   → crea GroupParticipation con ruolo default, status = 3 (accettata)
  # Altrimenti (accettazione con voto dei membri):
  #   → status = 2 (in votazione), la partecipazione sarà creata dopo il voto
  def participation_request_confirm
    authorize! :accept_requests, @group
    @request = @group.participation_requests.pending.find(params[:request_id])

    ActiveRecord::Base.transaction do
      if @group.request_by_portavoce?
        part = @group.group_participations.build(user: @request.user, acceptor: current_user, participation_role: @group.default_participation_role)
        @request.group_participation_request_status_id = 3
        part.save!
        @request.save!
      else
        @request.group_participation_request_status_id = 2
        @request.save!
      end
    end

    flash[:notice] = @group.request_by_portavoce? ? t('info.group_participations.status_accepted') : t('info.group_participations.status_voting')
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to group_url(@group) }
    end
  rescue ActiveRecord::ActiveRecordError
    flash[:error] = t('error.group_participations.error_saving')
    respond_to do |format|
      format.turbo_stream { render partial: 'layouts/flash_stream' }
      format.html { redirect_to group_url(@group) }
    end
  end

  # Rifiuta una richiesta di partecipazione pendente.
  # Se il gruppo decide per portavoce: status = 4 (rifiutata).
  # Se decide per voto: status = 2 (in votazione — i membri voteranno anche il rifiuto).
  # `find_by` (non `find`) per evitare eccezione se la richiesta è già stata gestita da un altro portavoce.
  def participation_request_decline
    authorize! :accept_requests, @group
    @request = @group.participation_requests.pending.find_by(id: params[:request_id])
    if !@request
      flash[:error] = t('error.group_participations.request_not_found')
      respond_to do |format|
        format.turbo_stream { render partial: 'layouts/flash_stream' }
        format.html { redirect_to group_url(@group) }
      end
    else
      @request.group_participation_request_status_id = @group.request_by_portavoce? ? 4 : 2
      saved = @request.save
      if !saved
        flash[:error] = t('error.group_participations.error_saving')
      else
        flash[:notice] = @group.request_by_portavoce? ?
          t('info.group_participations.status_declined') :
          t('info.group_participations.status_voting')
      end
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to group_url(@group) }
      end
    end
  end

  def change_advanced_options
    advanced_option = (params[:active] == 'true')
    @group.change_advanced_options = advanced_option
    if @group.save
      flash[:notice] = advanced_option ?
        t('info.quorums.can_modify_advanced_proposals_settings') :
        t('info.quorums.cannot_modify_advanced_proposals_settings')
    else
      flash[:error] = t('error.quorums.advanced_proposals_settings')
    end
    respond_to_group_setting
  end

  def change_default_anonima
    default_anonima = (params[:active] == 'true')
    @group.default_anonima = default_anonima
    if @group.save
      flash[:notice] = default_anonima ?
        t('info.quorums.anonymous_proposals') :
        t('info.quorums.non_anonymous_proposals')
    else
      flash[:error] = t('error.quorums.advanced_proposals_settings')
    end
    respond_to_group_setting
  end

  def change_default_visible_outside
    default_visible_outside = (params[:active] == 'true')
    @group.default_visible_outside = default_visible_outside
    if @group.save
      flash[:notice] = default_visible_outside ?
        t('info.quorums.public_proposals') :
        t('info.quorums.private_proposals')
    else
      flash[:error] = t('error.quorums.advanced_proposals_settings')
    end
    respond_to_group_setting
  end

  def change_default_secret_vote
    default_secret_vote = (params[:active] == 'true')
    @group.default_secret_vote = default_secret_vote
    if @group.save
      flash[:notice] = default_secret_vote ?
        t('info.quorums.secret_vote') :
        t('info.quorums.non_secret_vote')
    else
      flash[:error] = t('error.quorums.advanced_proposals_settings')
    end
    respond_to_group_setting
  end

  def reload_storage_size
    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  def enable_areas
    @group.update_attribute(:enable_areas, true)
    redirect_to group_group_areas_url @group
  end

  # Rimuove un post dal gruppo (elimina il `PostPublishing`, non il `BlogPost` originale).
  # Il post rimane nel blog personale dell'autore — viene solo dissociato dal gruppo.
  # Autorizzato se: portavoce del gruppo OPPURE autore del post.
  def remove_post
    raise StandardError unless (can? :remove_post, @group) || (can? :update, BlogPost.find(params[:post_id]))

    @publishing = @group.post_publishings.find_by(blog_post_id: params[:post_id])
    @publishing.destroy
    flash[:notice] = t('info.groups.post_removed')
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: group_path(@group) }
    end
  rescue StandardError
    flash[:error] = t('error.groups.post_removed')
    respond_to do |format|
      format.turbo_stream { render partial: 'layouts/flash_stream' }
      format.html { redirect_back fallback_location: group_path(@group) }
    end
  end

  # Alterna il flag `featured` sul `PostPublishing`.
  # I post featured appaiono in cima alla lista nel gruppo (ordinati per `featured desc`).
  def feature_post
    publishing = @group.post_publishings.find_by(blog_post_id: params[:post_id])
    publishing.update(featured: !publishing.featured)
    flash[:notice] = t("info.groups.post_featured.#{publishing.featured}")
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: group_path(@group) }
    end
  end

  def permissions_list
    @participation_role = @group.group_participations.find_by(user_id: current_user.id).participation_role
    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  protected

  # Pattern comune per le azioni di configurazione del gruppo (change_advanced_options, etc.).
  # Turbo Stream: mostra il flash in-page senza reload. HTML: redirect all'edit.
  def respond_to_group_setting
    respond_to do |format|
      format.turbo_stream { render partial: 'layouts/flash_stream' }
      format.html { redirect_back fallback_location: edit_group_path(@group) }
    end
  end

  def load_group
    @group = Group.friendly.find(params[:id])
  end

  def group_params
    params[:group][:default_role_actions]&.reject!(&:empty?)
    params.require(:group).permit(:participant_tokens, :name, :description,
                                  :accept_requests, :facebook_page_url, :group_participations,
                                  :interest_border_tkn, :title_bar, :default_role_name,
                                  :image, :admin_title, :private, :rule_book, :tags_list,
                                  :change_advanced_options, :default_anonima, :default_visible_outside, :default_secret_vote,
                                  default_role_actions: [])
  end

  def render_404(_exception = nil)
    # log_error(exception) if exception
    respond_to do |format|
      @title = I18n.t('error.error_404.groups.title')
      @message = I18n.t('error.error_404.groups.description')
      format.html { render 'errors/404', status: 404, layout: true }
    end
    true
  end

  private

  def choose_layout
    @group ? 'groups' : 'open_space'
  end
end
