# Controller base dell'applicazione. Tutti gli altri controller ereditano da qui.
#
# Responsabilità principali:
# - Gestione locale/dominio (`set_locale`, `set_current_domain`)
# - Fuso orario utente (`user_time_zone`)
# - Recupero sessione post-login (`after_sign_in_path_for`)
# - Autorizzazione CanCanCan (`permissions_denied`)
# - Tracking URL per redirect post-auth (`store_location`)
# - Helper metodi condivisi (`is_admin?`, `is_group_admin?`, `post_contribute`)
# - Error handling centralizzato (500, 404, locale invalido)
class ApplicationController < ActionController::Base
  include Pagy::Backend
  include StepsHelper
  include ApplicationHelper
  helper :all

  # L'ordine dei rescue_from è importante: StandardError deve essere l'ultimo (catch-all).
  # Non usare Exception: catturerebbe anche SystemExit e SignalException, impedendo lo shutdown corretto.
  rescue_from StandardError, with: :render_error
  rescue_from ActiveRecord::RecordNotFound, with: :render_404
  rescue_from ActionController::RoutingError, with: :render_404
  rescue_from ::AbstractController::ActionNotFound, with: :render_404
  rescue_from I18n::InvalidLocale, with: :invalid_locale

  protect_from_forgery
  # I flash XHR verrebbero mostrati sulla request successiva — li scartiamo subito.
  after_action :discard_flash_if_xhr

  before_action :store_location

  before_action :set_current_domain
  before_action :set_locale
  # `around_action` per time zone: avvolge l'intera action nel fuso orario dell'utente.
  around_action :user_time_zone, if: :current_user

  before_action :load_tutorial

  # Le API JSON non usano sessioni — il CSRF token non è richiesto.
  skip_before_action :verify_authenticity_token, if: proc { |c| c.request.format == 'application/json' }

  before_action :configure_permitted_parameters, if: :devise_controller?

  helper_method :is_admin?, :is_moderator?, :is_proprietary?, :current_url, :link_to_auth, :age, :is_group_admin?

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[username email name surname accept_conditions accept_privacy sys_locale_id password])
  end

  # Redirect post-login con recupero delle azioni pendenti in sessione.
  #
  # Casi gestiti (in ordine di priorità):
  # 1. L'utente stava tentando di commentare una proposta → esegui il commento e reindirizza alla proposta
  # 2. L'utente stava tentando di commentare un blog post → esegui il commento e reindirizza al post
  # 3. Redirect standard: `omniauth.origin` > `stored_location_for` > root_path
  #
  # I dati del commento pendente sono salvati in sessione da `ProposalsController` o `BlogPostsController`
  # quando l'utente non autenticato tenta di inviare un form.
  def after_sign_in_path_for(resource)
    # Se in sessione è memorizzato un contributo pendente, eseguilo prima del redirect
    if session[:proposal_comment] && session[:proposal_id]
      @proposal = Proposal.find_by(id: session[:proposal_id])
      comment_params = session[:proposal_comment].slice('content', 'parent_proposal_comment_id', 'section_id')
      session[:proposal_id] = nil
      session[:proposal_comment] = nil
      if @proposal
        @proposal_comment = @proposal.proposal_comments.build(
          ActionController::Parameters.new(comment_params).permit(:content, :parent_proposal_comment_id, :section_id)
        )
        post_contribute
        proposal_path(@proposal)
      else
        root_path
      end
    elsif session[:blog_comment] && session[:blog_post_id] && session[:blog_id]
      blog = Blog.friendly.find(session[:blog_id])
      blog_post = blog.blog_posts.find_by(id: session[:blog_post_id])
      pending_comment = session[:blog_comment]
      session[:blog_id] = nil
      session[:blog_post_id] = nil
      session[:blog_comment] = nil
      if blog_post
        blog_comment = blog_post.blog_comments.build(pending_comment)
        if save_blog_comment(blog_comment)
          flash[:notice] = t('info.blog.comment_added')
        else
          flash[:error] = t('error.blog.comment_added')
        end
        blog_blog_post_path(blog, blog_post)
      else
        root_path
      end
    else
      env = request.env
      ret = env['omniauth.origin'] || stored_location_for(resource) || root_path
      ret
    end
  end

  def save_blog_comment(blog_comment)
    blog_comment.user_id = current_user.id
    blog_comment.request = request
    blog_comment.save
  end

  def after_sign_up_path_for(_resource)
    proposals_path
  end

  protected

  # Carica il prossimo passo del tutorial onboarding per l'utente corrente.
  # Disabilitato in test per non interferire con le spec (i tutorial richiedono record in DB).
  def load_tutorial
    @step = get_next_step(current_user) if current_user && !Rails.env.test?
  end

  def load_group
    @group = Group.friendly.find(params[:group_id]) if params[:group_id].present?
  end

  def load_blog_data
    return unless @blog

    @user = @blog.user
    @pagy, @blog_posts = pagy(@blog.blog_posts.includes(:user, :blog, :tags), items: COMMENTS_PER_PAGE)
    @recent_comments = @blog.comments.includes(:blog_post, user: [:image]).order('created_at DESC').limit(10)
    @recent_posts = @blog.blog_posts.published.limit(10)
    @archives = @blog.blog_posts.
                select('COUNT(*) AS posts, extract(month from created_at) AS MONTH , extract(year from created_at) AS YEAR').
                group('MONTH, YEAR').
                order(Arel.sql('YEAR desc, extract(month from created_at) desc'))
  end

  def extract_locale_from_tld; end

  # Determina il dominio corrente (locale, territorio) dalla request.
  # Il parametro `?l=it-IT` ha priorità sul dominio — permette il cambio lingua esplicito.
  # Fallback a `SysLocale.default` se il dominio non è configurato.
  def set_current_domain
    @current_domain = if params[:l].present?
                        SysLocale.find_by(key: params[:l])
                      else
                        SysLocale.find_by(host: request.domain, lang: nil) || SysLocale.default
                      end
  end

  attr_reader :current_domain

  # Hook per i controller che vogliono esporre un territorio corrente (es. per i portlet).
  # Implementazione di default: nil (nessun territorio).
  def current_territory; end

  # Imposta il locale I18n per la request corrente.
  # In test/development usa sempre il locale di default per prevedibilità.
  # In produzione usa il locale del dominio o il parametro `?l=`.
  def set_locale
    @domain_locale = request.host.split('.').last
    @locale =
      if Rails.env.test? || Rails.env.development?
        params[:l].presence || I18n.default_locale
      else
        params[:l].blank? ? (current_domain.key || I18n.default_locale) : params[:l]
      end
    I18n.locale = @locale
  end

  # Avvolge l'intera action nel fuso orario dell'utente.
  # Se l'utente non ha un time_zone impostato, usa quello di default del sistema.
  def user_time_zone(&block)
    Time.use_zone(current_user.time_zone, &block)
  end

  # Aggiunge il parametro `l` alle URL generate solo se è diverso dal locale del dominio.
  # Evita URL con `?l=it-IT` ridondante quando si è già sul dominio italiano.
  def default_url_options(_options = {})
    !params[:l] || (params[:l] == @domain_locale) ? {} : { l: I18n.locale }
  end

  # Versione class-level per le URL generate fuori dal contesto di una request (es. mailer).
  def self.default_url_options(_options = {})
    { l: I18n.locale }
  end

  # Registra un'eccezione su Sentry (production) o sul log (development/test).
  # Per CanCan::AccessDenied aggiunge action e subject come extra context.
  # `rescue StandardError` nel begin/rescue protegge da oggetti subject malformati.
  #
  # @param exception [Exception]
  # @return [void]
  def log_error(exception)
    if defined?(Sentry)
      extra = {}
      extra[:current_user_id] = current_user.id if current_user
      if exception.instance_of? CanCan::AccessDenied
        extra[:action] = exception.action.to_s
        extra[:subject] = begin
                            exception.subject.class.class_name.to_s
                          rescue StandardError
                            nil
                          end
      end
      Sentry.with_scope do |scope|
        scope.set_extras(extra)
        Sentry.capture_exception(exception)
      end
    else
      message = "\n#{exception.class} (#{exception.message}):\n"
      Rails.logger.error(message)
      Rails.logger.error exception.backtrace.join("\n")
    end
  end

  # Gestisce errori 500 non attesi. Logga su Sentry e mostra una pagina/flash di errore.
  # Turbo Stream riceve un flash parziale (per update in-page), HTML riceve la pagina 500 intera.
  #
  # @param exception [Exception]
  # @return [void]
  def render_error(exception)
    log_error(exception)
    respond_to do |format|
      format.turbo_stream do
        flash.now[:error] = "<b>#{t('error.error_500.title')}</b></br>#{t('error.error_500.description')}"
        render partial: 'layouts/flash_stream', status: :internal_server_error
      end
      format.html do
        render template: 'errors/500', status: :internal_server_error, layout: 'application'
      end
    end
  end

  # Gestisce richieste con locale non valido (es. `?l=en` invece di `?l=en-EU`).
  # Reindirizza con 301 al locale corretto usando la mappa di sostituzione.
  # I codici lingua senza territorio (ISO 639-1) vengono mappati alla variante regionale usata dall'app.
  def invalid_locale(exception)
    locales_replacement = { en: :'en-EU',
                            zh: :'zh-TW',
                            ru: :'ru-RU',
                            fr: :'fr-FR',
                            pt: :'pt-PT',
                            hu: :'hu-HU',
                            el: :'el-GR',
                            de: :'de-DE' }.with_indifferent_access
    required_locale = params[:l]
    replacement_locale = locales_replacement[required_locale]
    log_error(exception)
    flash[:error] = 'You are asking for a locale which is not available, sorry'
    # to_unsafe_h è sicuro qui: i parametri servono solo per ricostruire la route, non vengono assegnati a modelli
    redirect_to url_for(params.to_unsafe_h.merge(l: replacement_locale, only_path: true)), status: :moved_permanently
  end

  def render_404(exception = nil)
    log_error(exception) if exception
    respond_to do |format|
      format.turbo_stream do
        flash.now[:error] = 'Page not available.'
        render partial: 'layouts/flash_stream', status: :not_found
      end
      format.html { render 'errors/404', status: :not_found, layout: 'application' }
    end
  end


  def current_url(overwrite = {})
    # to_unsafe_h è sicuro qui: i parametri servono solo per ricostruire l'URL corrente, non vengono assegnati a modelli
    url_for params.to_unsafe_h.merge(overwrite).merge(only_path: false)
  end

  # helper method per determinare se l'utente attualmente collegato è amministratore di sistema
  def is_admin?
    user_signed_in? && current_user.admin?
  end

  # helper method per determinare se l'utente attualmente collegato è amministratore di gruppo
  def is_group_admin?(group)
    (current_user && (group.portavoce.include? current_user)) || is_admin?
  end

  # helper method per determinare se l'utente attualmente collegato è amministratore di sistema
  def is_moderator?
    user_signed_in? && current_user.moderator?
  end

  # helper method per determinare se l'utente attualmente collegato è il proprietario di un determinato oggetto
  def is_proprietary?(object)
    current_user&.is_mine?(object)
  end

  # Calcola l'età in anni interi a partire da una data di nascita.
  # Sottrae 1 se il compleanno non è ancora passato nell'anno corrente.
  #
  # @param birthdate [Date]
  # @return [Integer]
  def age(birthdate)
    today = Date.today
    a = today.year - birthdate.year
    a -= 1 if birthdate.month > today.month || (birthdate.month >= today.month && birthdate.day > today.day)
    a
  end

  def link_to_auth(_text, _link)
    '<a>login</a>'
  end

  def title(ttl)
    @page_title = ttl
  end

  # Gate: permette solo agli admin di proseguire, altrimenti chiama `admin_denied`.
  # @return [Boolean, void]
  def admin_required
    is_admin? || admin_denied
  end

  # Gate: permette ad admin e moderatori di proseguire, altrimenti chiama `admin_denied`.
  # @return [Boolean, void]
  def moderator_required
    is_admin? || is_moderator? || admin_denied
  end

  # Risponde con 403 Forbidden agli utenti non autorizzati.
  # Turbo Stream: flash parziale in-page. HTML: redirect back con flash error.
  #
  # @return [void]
  def admin_denied
    respond_to do |format|
      format.turbo_stream do
        flash.now[:error] = t('error.admin_required')
        render partial: 'layouts/flash_stream', status: :forbidden
      end
      format.html do
        store_location
        flash[:error] = t('error.admin_required')
        redirect_back(fallback_location: proposals_path)
      end
    end
  end

  def redirect_to_back(path)
    redirect_back(fallback_location: path)
  end

  # Gestisce i CanCan::AccessDenied (rescue_from in fondo al file).
  # - Utente loggato senza permessi → mostra errore (403)
  # - Utente non loggato → redirect al login (Devise gestisce il ritorno)
  # Il comportamento differisce per formato: Turbo Stream usa un flash parziale, HTML una pagina dedicata.
  def permissions_denied(exception = nil)
    respond_to do |format|
      format.turbo_stream do
        if current_user
          log_error(exception)
          flash.now[:error] = exception.message
          render partial: 'layouts/flash_stream', status: :forbidden
        else
          redirect_to new_user_session_path
        end
      end
      format.html do
        if current_user
          log_error(exception)
          flash[:error] = exception.message
          render 'errors/access_denied', status: :forbidden
        else
          redirect_to new_user_session_path
        end
      end
      format.all do
        log_error(exception)
        render plain: 'Permission denied', status: :forbidden
      end
    end
  end

  # Memorizza l'URL corrente in sessione per il redirect post-login.
  # Pulisce anche i dati di commento pendente quando l'utente naviga (non è più in attesa di login).
  def store_location
    return if skip_store_location?

    session[:proposal_id] = nil
    session[:proposal_comment] = nil
    session[:user_return_to] = request.url
  end

  # Non memorizza l'URL per:
  # - Request XHR (navigazione parziale, non navigazioni intere)
  # - Request non-GET (POST/PATCH/DELETE non sono pagine visitabili)
  # - Controller Devise (login/logout/password — causerebbero loop di redirect)
  # - Alert index (la pagina notifiche è troppo generica come "return_to")
  # - Azioni di join/conferma credenziali (flussi OAuth intermedi)
  def skip_store_location?
    request.xhr? || !params[:controller] || !request.get? ||
      (params[:controller].starts_with? 'devise/') ||
      (params[:controller] == 'passwords') ||
      (params[:controller] == 'sessions') ||
      (params[:controller] == 'users/omniauth_callbacks') ||
      (params[:controller] == 'alerts' && params[:action] == 'index') ||
      (params[:controller] == 'users' && (%w[join_accounts confirm_credentials].include? params[:action])) ||
      (params[:action] == 'feedback')
  end

  # Salva il commento/contributo corrente e assegna automaticamente un ranking positivo.
  # Usato sia da `ProposalsController#create_comment` sia da `after_sign_in_path_for`
  # (quando un utente non loggato tenta di commentare e poi si autentica).
  #
  # Il ranking_type_id `:positive` corrisponde al voto positivo (ID 1).
  # La distinzione contribute/reply cambia solo il flash message mostrato.
  #
  # @raise [ActiveRecord::RecordInvalid] se il commento non supera le validazioni
  # @return [void]
  def post_contribute
    ProposalComment.transaction do
      @proposal_comment.user_id = current_user.id
      @proposal_comment.request = request
      @proposal_comment.save!
      @ranking = ProposalCommentRanking.new
      @ranking.user_id = current_user.id
      @ranking.proposal_comment_id = @proposal_comment.id
      @ranking.ranking_type_id = :positive
      @ranking.save!

      @generated_nickname = @proposal_comment.nickname_generated

      if @proposal_comment.is_contribute?
        # if it's lateral show a message, else show show another message
        if @proposal_comment.paragraph
          @section = @proposal_comment.paragraph.section
          flash[:notice] = if params[:right]
                             t('info.proposal.contribute_added')
                           else
                             t('info.proposal.contribute_added_right', section: @section.title)
                           end
        else
          flash[:notice] = t('info.proposal.contribute_added')
        end
      else
        flash[:notice] = t('info.proposal.comment_added')
      end
    end
  end

  def discard_flash_if_xhr
    flash.discard if request.xhr?
  end

  rescue_from CanCan::AccessDenied do |exception|
    permissions_denied(exception)
  end

  # Marca come letti tutti gli alert dell'utente relativi alla risorsa corrente.
  # Va chiamato come `after_action` nei controller che gestiscono risorse notificabili.
  # Usa JSONB query PostgreSQL per filtrare gli alert per `proposal_id` o `blog_post_id`.
  # Mostra anche un banner informativo se ci sono autori disponibili (AVAILABLE_AUTHOR).
  #
  # @return [void]
  def check_page_alerts
    return unless current_user

    case params[:controller]
    when 'proposals'
      case params[:action]
      when 'show'
        # mark as checked all user alerts about this proposal
        @unread = current_user.alerts.joins(:notification).where(["(notifications.properties -> 'proposal_id') = ? and alerts.checked = ?", @proposal.id.to_s, false])
        flash[:info] = t('info.proposal.available_authors') if @unread.where(['notifications.notification_type_id = ?', NotificationType::AVAILABLE_AUTHOR]).exists?
        @unread.check_all
      end
    when 'blog_posts'
      case params[:action]
      when 'show'
        # mark as checked all user alerts about this proposal
        @unread = current_user.alerts.joins(:notification).where(["(notifications.properties -> 'blog_post_id') = ? and alerts.checked = ?", @blog_post.id.to_s, false])
        @unread.check_all
      end
    end
  end

  private

  # Delega l'autorizzazione admin del forum a CanCanCan (`can? :update, group`).
  # Usato internamente dal motore Forem per proteggere le azioni di moderazione.
  #
  # @param group [Group]
  # @return [Boolean]
  def forem_admin?(group)
    can? :update, group
  end

  helper_method :forem_admin?

  def forem_admin_or_moderator?(forum)
    can? :update, forum.group || forum.moderator?(current_user)
  end

  helper_method :forem_admin_or_moderator?

  # URL corretto per una proposta: nested sotto il gruppo se privata, standalone se pubblica.
  # Le proposte private esistono solo nel contesto del gruppo, quindi l'URL deve includere il gruppo.
  #
  # @param proposal [Proposal]
  # @return [String]
  def redirect_url(proposal)
    proposal.private? ? group_proposal_url(proposal.groups.first, proposal) : proposal_url(proposal)
  end
end
