# Controller CRUD per le proposte. Gestisce il ciclo di vita completo:
# creazione, dibattito (ranking), chiusura dibattito, votazione, risultati.
#
# Le proposte possono essere pubbliche (open space) o private (dentro un gruppo).
# Per quelle private, le route sono nested sotto `group` o `group_area`:
#   GET /groups/:group_id/proposals        → index nel gruppo
#   GET /proposals                         → open space
#
# CanCanCan usa `load_and_authorize_resource` con `through: [:group, :group_area]`
# per caricare `@proposal` in modo sicuro e verificare i permessi in ogni azione.
class ProposalsController < ApplicationController
  include ProposalsHelper

  before_action :load_group
  before_action :load_group_area

  # Autorizza l'accesso al contesto parent prima di autorizzare la proposta stessa.
  # Necessario per le route nested: senza questo, CanCan autorizzerebbe la proposta
  # senza verificare se l'utente può accedere al gruppo/area contenitore.
  before_action :authorize_parent

  def authorize_parent
    authorize! :read, @group if @group
    authorize! :read, @group_area if @group_area
  end

  # `shallow: true` → le azioni che agiscono su una proposta esistente (show, edit, update, destroy)
  # usano la route non-nested `/proposals/:id`, mentre index/new restano nested.
  # `except: tab_list/similar/endless_index` → queste azioni gestiscono la propria autorizzazione.
  load_and_authorize_resource through: %i[group group_area], shallow: true, except: %i[tab_list similar endless_index]
  skip_authorize_resource only: :vote_results

  layout :choose_layout

  # la proposta deve essere in stato 'IN VALUTAZIONE'
  before_action :valutation_state_required, only: %i[rankup rankdown available_author add_authors geocode]

  before_action :check_page_alerts, only: :show

  # Mostra la lista paginata delle proposte con i contatori per tab (debate/votation/voted/revision).
  # I contatori vengono calcolati separatamente dalla lista paginata tramite `@search.counters`
  # per non eseguire 4 query COUNT separate — SearchProposal fa tutto in un'unica query GROUP BY.
  def index
    if @group
      authorize! :view_data, @group

      unless can? :view_proposal, @group
        flash.now[:warn] = t('error.proposals.no_permission_to_view', default: 'You do not have permission to view private proposals. Contact the group administrators.')
      end

      if params[:group_area_id]
        unless can? :view_proposal, @group_area
          flash.now[:warn] = t('error.proposals.no_permission_to_view', default: 'You do not have permission to view private proposals. Contact the group administrators.')
        end
      end
    end
    @search = populate_search
    # `nil` per i counters: non filtrare per stato, così i contatori coprono tutti i tab.
    @search.proposal_state_tab = nil
    counters = @search.counters
    @in_valutation_count = counters[ProposalState::TAB_DEBATE]
    @in_votation_count = counters[ProposalState::TAB_VOTATION]
    @accepted_count = counters[ProposalState::TAB_VOTED]
    @revision_count = counters[ProposalState::TAB_REVISION]

    query_index

    respond_to do |format|
      format.html do
        generate_page_head
        @page_title = @page_head
      end
      format.json
    end
  end

  # Restituisce la lista delle proposte per uno specifico tab (debate/votation/voted/revision).
  # Usato da Turbo Stream per aggiornare solo il contenuto del tab attivo senza ricaricare la pagina.
  def tab_list
    authorize! :index, Proposal
    query_index
    respond_to do |format|
      format.html do
        render 'tab_list', layout: false
      end
      format.turbo_stream
      format.json
    end
  end

  # Carica la pagina successiva delle proposte per l'infinite scroll (Turbo Stream).
  # Il Stimulus `infinite_scroll_controller` triggera questa azione al raggiungimento del fondo.
  def endless_index
    authorize! :index, Proposal
    query_index
    respond_to do |format|
      format.turbo_stream
    end
  end

  def banner
    @proposal = Proposal.find(params[:id])
    respond_to do |format|
      format.html { render 'banner', layout: false }
      format.turbo_stream
    end
  end

  def test_banner
    @proposal = Proposal.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  # Mostra la pagina di dettaglio della proposta. Gestisce tre scenari di visibilità:
  # 1. Proposta pubblica → accessibile a tutti
  # 2. Proposta privata `visible_outside: true` → visibile ma non partecipabile dall'esterno
  # 3. Proposta privata `visible_outside: false` → solo membri del gruppo
  #
  # `check_phase` valuta se il quorum è scaduto e aggiorna lo stato prima della visualizzazione.
  # `reload` è necessario perché `check_phase` può modificare lo stato via `update_columns`.
  def show
    return redirect_to redirect_url(@proposal) if wrong_url?

    @proposal.check_phase
    @proposal.reload
    if @proposal.private
      if @proposal.visible_outside
        if !current_user
          flash[:info] = I18n.t('info.proposal.ask_participation')
        elsif !(can? :participate, @proposal) && @proposal.in_valutation?
          flash[:info] = I18n.t('error.proposals.participate')
        end
      else
        if !current_user
          authenticate_user!
        elsif !(can? :show, @proposal)
          respond_to do |format|
            flash[:error] = I18n.t('error.proposals.view_proposal')
            format.html do
              redirect_to group_proposals_path(@group)
            end
            format.json do
              render json: { error: flash[:error] }, status: 401
              return
            end
          end
        end
        flash[:info] = I18n.t('error.proposals.participate') if !(can? :participate, @proposal) && @proposal.in_valutation?
      end
    end

    # Il nickname anonimo è specifico per proposta — ogni utente ha uno pseudonimo diverso per proposta.
    @my_nickname = current_user.proposal_nicknames.find_by(proposal_id: @proposal.id) if current_user

    load_my_vote
    respond_to do |format|
      format.html do
        flash.now[:info] = I18n.t('info.proposal.public_visible') if @proposal.visible_outside
        register_view(@proposal, current_user)
        @blocked_alerts = BlockedProposalAlert.find_by(user_id: current_user.id, proposal_id: @proposal.id) if current_user
        flash.now[:info] = I18n.t('info.proposal.voting') if @proposal.voting?
      end
      format.turbo_stream do
        head :ok
      end
      format.json
      format.pdf do
        render pdf: 'show.pdf.erb',
               show_as_html: params[:debug].present?
      end
    end
  end

  def promote
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  # Form di creazione proposta. Inizializza la struttura della proposta in base al tipo.
  # `LIMIT_PROPOSALS` (costante di configurazione) abilita il rate limiting anti-spam:
  # l'utente deve aspettare `PROPOSALS_TIME_LIMIT` tra una proposta e l'altra.
  def new
    if LIMIT_PROPOSALS
      max = current_user.proposals.maximum(:created_at) || Time.zone.now - (PROPOSALS_TIME_LIMIT + 1.second)
      @elapsed = Time.zone.now - max
      if @elapsed < PROPOSALS_TIME_LIMIT
        respond_to do |format|
          format.turbo_stream { render 'error_new' }
        end
        return
      end
    end

    if @group
      @proposal.interest_borders << @group.interest_border
      @proposal.private = true
      @proposal.anonima = @group.default_anonima
      @proposal.visible_outside = @group.default_visible_outside
      @proposal.change_advanced_options = @group.change_advanced_options

      @proposal.group_area_id = params[:group_area_id] if params[:group_area_id]

      if params[:topic_id]
        @topic = @group.topics.find(params[:topic_id])
        (@proposal.topic_id = params[:topic_id]) if can? :read, @topic
      end
    end

    @proposal.proposal_category_id = params[:category] || ProposalCategory.find_by(name: 'no_category').id

    @proposal.proposal_type = ProposalType.find_by(name: (params[:proposal_type_id] || ProposalType::SIMPLE))

    @proposal.build_sections
    @title = ''
    @title += "Create a new #{@proposal.proposal_type.description}"
  end

  def edit
    @proposal.change_advanced_options = @group ?
      @group.change_advanced_options :
      DEFAULT_CHANGE_ADVANCED_OPTIONS
  end

  def geocode; end

  # Crea la proposta. Doppio check LIMIT_PROPOSALS (anche in `new`) per prevenire abuse via direct POST.
  # `current_user_id` viene assegnato dopo la build CanCan perché i model callback lo richiedono.
  def create
    max = current_user.proposals.maximum(:created_at) || Time.zone.now - (PROPOSALS_TIME_LIMIT + 1.second)
    raise StandardError if LIMIT_PROPOSALS && ((Time.zone.now - max) < PROPOSALS_TIME_LIMIT)

    @proposal.current_user_id = current_user.id
    if @proposal.save
      respond_to do |format|
        flash[:notice] = I18n.t('info.proposal.proposal_created')
        format.html do
          if request.env['HTTP_REFERER']['back=home']
            redirect_to home_url
          else
            redirect_to @group ? edit_group_proposal_url(@group, @proposal) : edit_proposal_path(@proposal)
          end
        end
      end
    else
      Rails.logger.error("Error while creating a Proposal. #{@proposal.errors.details}")
      if @proposal.errors[:title].present?
        @other = Proposal.find_by(title: @proposal.title)
        @err_msg = t('error.proposals.same_title')
      elsif !@proposal.errors.empty?
        @err_msg = @proposal.errors.full_messages.join(',')
      else
        @err_msg = I18n.t('error.proposals.creation')
      end
      respond_to do |format|
        format.html { render action: :new }
      end
    end
  end

  # put back in debate a proposal
  def regenerate
    authorize! :regenerate, @proposal
    @proposal.current_user_id = current_user.id
    @proposal.regenerate(regenerate_proposal_params)
    flash[:notice] = t('info.proposal.back_in_debate')
    respond_to do |format|
      format.turbo_stream
      format.html do
        redirect_to redirect_url(@proposal)
      end
    end
  end

  def update
    @proposal.current_user_id = current_user.id
    if @proposal.update(update_proposal_params)
      Turbo::StreamsChannel.broadcast_action_to(@proposal, action: :refresh, target: "")
      respond_to do |format|
        flash.now[:notice] = I18n.t('info.proposal.proposal_updated')
        format.html do
          if params[:commit_exit]
            redirect_to @group ? group_proposal_url(@group, @proposal) : @proposal
          else
            @proposal.reload
            render action: 'edit'
          end
        end
      end
    else
      flash[:error] = @proposal.errors.map { |_e, msg| msg }[0].to_s
      respond_to do |format|
        format.html { render action: 'edit' }
      end
    end
  end

  def set_votation_date
    if @proposal.waiting_date?
      @proposal.set_votation_date(params[:proposal][:vote_period_id])
      flash[:notice] = I18n.t('info.proposal.date_selected')
    else
      flash[:error] = I18n.t('error.proposals.proposal_not_waiting_date')
    end
    redirect_to @group ? group_proposal_url(@group, @proposal) : proposal_url(@proposal)
  end

  def destroy
    authorize! :destroy, @proposal
    @proposal.destroy
    flash[:notice] = I18n.t('info.proposal.proposal_deleted')
    redirect_to @group ? group_proposals_url(@group) : proposals_url
  end

  # Voto positivo (ranking_type_id = 1). Delega a `rank`.
  def rankup
    rank 1
  end

  # Voto negativo (ranking_type_id = 3). Delega a `rank`.
  def rankdown
    rank 3
  end

  # Restituisce proposte simili tramite `SearchProposal#similar` (pg_search con `any_word: true`).
  # Usato nel form di creazione per avvisare l'utente di duplicati potenziali prima di salvare.
  def similar
    authorize! :index, Proposal
    search = SearchProposal.new
    search.add_tags_and_title(params[:tags], params[:title])
    search.user_id = current_user.id if current_user
    search.group_id = @group.id if @group
    @proposals = search.similar

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  # Aggiunge l'utente corrente come autore disponibile per la redazione della sintesi.
  # Il portavoce vedrà gli autori disponibili e potrà scegliere chi co-redige la revisione.
  def available_author
    @proposal.available_user_authors << current_user
    @proposal.save!
    flash[:notice] = I18n.t('info.proposal.offered_editor')
  end

  # Lista degli autori disponibili — renderizzata via Turbo Stream nel pannello del portavoce.
  def available_authors_list
    @available_authors = @proposal.available_user_authors
    respond_to do |format|
      format.turbo_stream
    end
  end

  # Promuove gli autori disponibili selezionati ad autori effettivi della proposta.
  # Rimuove dalla lista degli available e aggiunge `ProposalPresentation` con l'accettante (portavoce).
  # Tutto in transazione: se un'assegnazione fallisce, nessuna viene salvata.
  def add_authors
    available_ids = params['user_ids']
    Proposal.transaction do
      users = @proposal.available_user_authors.where(users: { id: available_ids.map(&:to_i) })
      @proposal.available_user_authors -= users
      users.each do |user|
        @proposal.proposal_presentations.build(user: user, acceptor: current_user)
      end
      @proposal.save!
      @proposal.reload
    end
    flash[:notice] = t('info.proposal.authors_added')
  rescue StandardError
    flash[:error] = t('errors.proposal.authors_added')
    respond_to do |format|
      format.turbo_stream { render partial: 'layouts/flash_stream' }
      format.html { redirect_back fallback_location: proposal_path(@proposal) }
    end
  end

  def vote_results
    return redirect_to vote_results_group_proposal_path(@proposal.group, @proposal) if wrong_url?

    authorize! :show, @proposal
  end

  # Chiusura anticipata del dibattito da parte del portavoce (`force_end: true`).
  # `check_phase(true)` ignora il timer e forza la valutazione del quorum immediatamente.
  def close_debate
    authorize! :close_debate, @proposal
    @proposal.check_phase(true)
    redirect_to @proposal
  end

  # Avvio manuale della votazione (portavoce). Bypassa il timer di attesa.
  # `Proposal#start_votation` schedula i job STARTVOTATION/ENDVOTATION.
  def start_votation
    @proposal.start_votation
    redirect_to @proposal
  end

  protected

  # Una proposta privata deve essere sempre accessibile via URL nested (`/groups/:id/proposals/:id`).
  # Se l'utente accede a `/proposals/:id` per una proposta privata, reindirizzo alla URL canonica.
  # Previene anche la discovery indiretta di proposte private tramite ID progressivo.
  #
  # @return [Boolean]
  def wrong_url?
    @proposal.private? && !@group
  end

  def choose_layout
    @group ? 'groups' : 'open_space'
  end

  # Esegue la query di ricerca e popola `@proposals` paginata con Pagy.
  # @return [void]
  def query_index
    @search = populate_search
    @pagy, @proposals = pagy(@search.results, items: @search.per_page || 10)
  end

  # Salva o aggiorna il ranking dell'utente sulla proposta.
  # `find_or_create_by` evita duplicati: un utente ha un solo ranking per proposta.
  # La transazione garantisce che reload e load_my_vote vedano lo stato aggiornato.
  # In caso di errore (es. validazione), mostra il template `proposals/errors/rank`.
  #
  # @param rank_type [Integer] 1 = positivo, 3 = negativo
  # @return [void]
  def rank(rank_type)
    ProposalRanking.transaction do
      ranking = @proposal.rankings.find_or_create_by(user_id: current_user.id)
      ranking.ranking_type_id = rank_type
      ranking.save!
      @proposal.reload
      load_my_vote
    end

    flash[:notice] = I18n.t('info.proposal.rank_recorderd')
    respond_to do |format|
      format.turbo_stream { render 'rank' }
      format.html { redirect_back(fallback_location: proposal_path(@proposal)) }
    end
  rescue StandardError => e
    log_error(e)
    flash[:error] = I18n.t('error.proposals.proposal_rank')
    respond_to do |format|
      format.html { redirect_back(fallback_location: proposal_path(@proposal)) }
      format.turbo_stream { render 'proposals/errors/rank' }
    end
  end

  # carica l'area di lavoro
  def load_group_area
    @group_area = @group.group_areas.find(params[:group_area_id]) if @group && params[:group_area_id]
  end

  # Carica il voto corrente dell'utente e stabilisce se può votare di nuovo.
  # `@can_vote_again` è true in due casi:
  # 1. L'utente non ha ancora votato
  # 2. La proposta è stata aggiornata dopo l'ultimo voto (ranking.updated_at < proposal.updated_at)
  #    → il testo è cambiato, l'utente dovrebbe rivalutare
  #
  # @return [void]
  def load_my_vote
    return unless @proposal.in_valutation?

    ranking = ProposalRanking.find_by(user_id: current_user.id, proposal_id: @proposal.id) if current_user
    @my_vote = ranking.ranking_type_id if ranking

    if @my_vote
      if ranking.updated_at < @proposal.updated_at
        flash.now[:info] = I18n.t('info.proposal.can_change_valutation') if %w[show update].include? params[:action]
        @can_vote_again = true
      end
    else
      @can_vote_again = true
    end
  end

  # Guard: blocca le azioni di dibattito (rankup, rankdown, available_author)
  # se la proposta non è più in stato VALUTATION. Risponde con flash error.
  #
  # @return [void]
  def valutation_state_required
    return if @proposal.in_valutation?

    flash[:error] = I18n.t('error.proposals.proposal_not_valuating')
    respond_to do |format|
      format.html { redirect_back(fallback_location: proposal_path(@proposal)) }
      format.turbo_stream { render 'proposals/errors/rank', layout: false }
    end
  end

  # Costruisce il `SearchProposal` dai parametri della request.
  # `interest_border` di default: il territorio del dominio corrente (locale geografico).
  # I timestamp di `params[:time]` arrivano in millisecondi da JS — divisi per 1000 per i secondi Unix.
  # `search.or = params[:or]` attiva la modalità OR tra tag e testo (meno precisa, più risultati).
  #
  # @return [SearchProposal]
  def populate_search
    search = SearchProposal.new
    search.order_id = params[:view]
    search.order_dir = params[:order]

    search.user_id = current_user.id if current_user

    search.proposal_type_id = params[:type]

    search.proposal_state_tab = (params[:state] || ProposalState::TAB_DEBATE)

    search.proposal_category_id = params[:category]

    search.interest_border = if params[:interest_border].nil?
                               InterestBorder.find_or_create_by(territory: current_domain.territory)
                             else
                               InterestBorder.find_or_create_by_key(params[:interest_border])
                             end

    if @group
      search.group_id = @group.id
      if params[:group_area_id]
        @group_area = GroupArea.find(params[:group_area_id])
        search.group_area_id = params[:group_area_id]
      end
    end

    if params[:time]
      # I timestamp arrivano in millisecondi dal datepicker JS
      search.created_at_from = Time.zone.at(params[:time][:start].to_i / 1000) if params[:time][:start]
      search.created_at_to = Time.zone.at(params[:time][:end].to_i / 1000) if params[:time][:end]
      search.time_type = params[:time][:type]
    end
    search.text = params[:search]
    search.or = params[:or]

    search.page = params[:page] || 1
    search.per_page = PROPOSALS_PER_PAGE
    search
  end

  private

  def generate_page_head
    @page_head = ''

    @page_head += if params[:category]
                    t('pages.proposals.index.title_with_category', category: ProposalCategory.find(params[:category]).description)
                  else
                    t('pages.proposals.index.title')
                  end

    @page_head += " #{t('pages.propsoals.index.type', type: ProposalType.find(params[:type]).description)}" if params[:type]

    if params[:time]
      if params[:time][:type] == 'f'
        @page_head += " #{t('pages.proposals.index.date_range', start: params[:time][:start_w], end: params[:time][:end_w])}"
      elsif params[:time][:type] == '1h'
        @page_head += " #{t('pages.proposals.index.last_1h')}"
      elsif params[:time][:type] == '24h'
        @page_head += " #{t('pages.proposals.index.last_24h')}"
      elsif params[:time][:type] == '7d'
        @page_head += " #{t('pages.proposals.index.last_7d')}"
      elsif params[:time][:type] == '1m'
        @page_head += " #{t('pages.proposals.index.last_1m')}"
      elsif params[:time][:type] == '1y'
        @page_head += " #{t('pages.proposals.index.last_1y')}"
      end
    end
    @page_head += " #{t('pages.proposals.index.with_text', text: params[:search])}" if params[:search]
    @page_head += " #{t('pages.proposals.index.in_group_area_title')} '#{@group_area.name}'" if @group_area
  end

  def proposal_params
    params.require(:proposal).permit(:proposal_category_id, :content, :title, :interest_borders_tkn, :tags_list,
                                     :private, :anonima, :quorum_id, :visible_outside, :secret_vote, :vote_period_id, :group_area_id, :topic_id,
                                     :proposal_type_id, :proposal_votation_type_id,
                                     :integrated_contributes_ids_list, :signatures, :petition_phase,
                                     votation: %i[later start start_edited end],
                                     sections_attributes:
                                       [:id, :seq, :_destroy, :title, paragraphs_attributes:
                                         %i[id seq content content_dirty]],
                                     solutions_attributes:
                                       [:id, :seq, :_destroy, :title, sections_attributes:
                                         [:id, :seq, :_destroy, :title, paragraphs_attributes:
                                           %i[id seq content content_dirty]]])
  end

  # I campi strutturali (titolo, territorio, quorum, anonimato, visibilità, voto segreto) possono essere
  # modificati solo da chi ha il permesso `:destroy` (= portavoce/autore).
  # Gli altri autori co-redattori possono modificare solo il contenuto testuale.
  def update_proposal_params
    (can? :destroy, @proposal) ?
      proposal_params :
      proposal_params.except(:title, :interest_borders_tkn, :tags_list, :quorum_id, :anonima, :visible_outside, :secret_vote)
  end

  def regenerate_proposal_params
    params.require(:proposal).permit(:quorum_id)
  end

  def render_404(exception = nil)
    log_error(exception) if exception
    respond_to do |format|
      @title = I18n.t('error.error_404.proposals.title')
      @message = I18n.t('error.error_404.proposals.description')
      format.html { render 'errors/404', status: 404, layout: true }
    end
    true
  end

  def register_view(proposal, user)
    proposal.register_view_by(user)
  end
end
