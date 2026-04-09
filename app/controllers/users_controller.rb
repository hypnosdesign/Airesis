# Controller per il profilo utente, preferenze e flussi OAuth account-linking.
#
# Il flusso di account-linking OmniAuth si svolge in due step:
# 1. `confirm_credentials` — mostra il form dove l'utente inserisce la password del suo account esistente
# 2. `join_accounts` — verifica la password e chiama `User#oauth_join` per collegare i provider
#
# Questo è necessario quando OmniAuth trova un'email già presente nel DB di Airesis
# (es. l'utente si era registrato via email e ora prova a loggarsi con Facebook con la stessa email).
class UsersController < ApplicationController
  include UsersHelper
  layout :choose_layout

  before_action :authenticate_user!, except: %i[index show confirm_credentials join_accounts]

  before_action :load_user, only: %i[show update show_message send_message]

  # Step 1 del flusso di account-linking.
  # `User.new_with_session(nil, session)` ricostruisce un User temporaneo dai dati OAuth
  # memorizzati in sessione da Devise OmniAuth (chiave `devise.omniauth_data`).
  # `@orig` è l'account esistente da collegare, mostrato nel form per conferma visiva.
  def confirm_credentials
    @user = User.new_with_session(nil, session)
    @orig = User.find_by(email: @user.email)
  end

  # Step 2 del flusso di account-linking: collega l'account OAuth all'account email esistente.
  # Se la password è corretta, chiama `User#oauth_join` che aggiunge l'`Authentication` OAuth
  # e poi autentica l'utente con `sign_in_and_redirect`.
  def join_accounts
    oauth_data = session['devise.omniauth_data']
    oauth_data_parser = OauthDataParser.new(oauth_data)
    oauth_data_parser.raw_info
    user_info = oauth_data_parser.user_info

    if wrong_join_accounts_params?
      flash[:error] = t('error.users.join_accounts')
      return redirect_to confirm_credentials_users_url
    end

    user = User.find_by(email: user_info[:email])
    unless user
      flash[:error] = t('error.users.join_accounts')
      return redirect_to confirm_credentials_users_url
    end

    if user.valid_password?(params[:user][:password])
      user.oauth_join(oauth_data)
      flash[:notice] = t('info.user.account_joined')
      sign_in_and_redirect user, event: :authentication
    else
      flash[:error] = t('error.users.join_accounts_password')
      redirect_to confirm_credentials_users_url
    end
  end

  # Lista utenti per ricerca/autocomplete.
  # Gli utenti già loggati vengono redirectati alla home — la pagina è pensata per i visitatori.
  def index
    return redirect_to root_path if user_signed_in?

    @users = User.where('upper(name) like upper(?)', "%#{params[:q].to_s.first(50)}%")

    respond_to do |format|
      format.html
      format.json { render json: @users.to_json(only: %i[id name]) }
    end
  end

  def show
    respond_to do |format|
      flash.now[:info] = t('info.user.click_to_change') if current_user == @user
      format.html # show.html.erb
    end
  end

  def alarm_preferences
    @user = current_user
    respond_to do |format|
      flash.now[:info] = t('info.user.click_to_change') if current_user == @user
      format.html # show.html.erb
    end
  end

  def border_preferences
    @user = current_user
  end

  def privacy_preferences
    @user = current_user
  end

  # Statistiche personali di partecipazione: contributi integrati, spam segnalati, rumorosi.
  # I scope `.contributes` filtrano solo i commenti top-level (parent_proposal_comment_id nil),
  # escludendo le risposte — le statistiche riguardano solo i contributi al dibattito.
  def statistics
    @user = current_user
    @integrated_count = @user.proposal_comments.contributes.integrated.count
    @spam_count = @user.proposal_comments.contributes.spam.count
    @noisy_count = @user.proposal_comments.contributes.noisy.count
    @contributes_count = @user.proposal_comments.contributes.count
    @comments_count = @user.proposal_comments.comments.count
    @proposals_count = @user.proposals.count
  end

  def change_show_tooltips
    current_user.show_tooltips = params[:active]
    current_user.save!
    flash[:notice] = params[:active] == 'true' ? t('info.user.tooltips_enabled') : t('info.user.tooltips_disabled')
    respond_to_preference
  rescue StandardError
    flash[:error] = t('error.setting_preferences')
    respond_to_preference
  end

  def change_show_urls
    current_user.show_urls = params[:active]
    current_user.save!
    flash[:notice] = params[:active] == 'true' ? t('info.user.url_shown') : t('info.user.url_hidden')
    respond_to_preference
  rescue StandardError
    flash[:error] = t('error.setting_preferences')
    respond_to_preference
  end

  def change_receive_messages
    current_user.receive_messages = params[:active]
    current_user.save!
    flash[:notice] = if params[:active] == 'true'
                       t('info.private_messages_active')
                     else
                       t('info.private_messages_inactive')
                     end
    respond_to_preference
  rescue StandardError
    flash[:error] = t('error.setting_preferences')
    respond_to_preference
  end

  def change_locale
    current_user.locale = SysLocale.find(params[:locale])
    current_user.save!
    flash[:notice] = t('info.locale_changed')
    respond_to_preference
  rescue StandardError
    flash[:error] = t('error.setting_preferences')
    respond_to_preference
  end

  def change_time_zone
    current_user.time_zone = params[:time_zone]
    current_user.save!
    flash[:notice] = t('info.user.time_zone_changed')
    respond_to_preference
  rescue StandardError
    flash[:error] = t('error.setting_preferences')
    respond_to_preference
  end

  # Abilita/disabilita la 2FA TOTP (ROTP gem).
  # Alla prima abilitazione genera un secret Base32 casuale — il QR code verrà mostrato nella view.
  # Il secret non viene rigenerato alla disabilitazione per permettere la riattivazione rapida.
  def change_rotp_enabled
    authorize! :change_rotp_enabled, current_user
    current_user.rotp_enabled = params[:active]
    if params[:active] == 'true'
      current_user.rotp_secret = ROTP::Base32.random_base32
      flash[:notice] = t('info.rotp_active')
    else
      flash[:notice] = t('info.rotp_inactive')
    end
    current_user.save!
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: root_path }
    end
  rescue StandardError
    flash[:error] = t('error.setting_preferences')
    respond_to_preference
  end

  def update
    respond_to do |format|
      if @user.update(user_params)
        flash[:notice] = t('info.user.info_updated')
        flash[:notice] += t('info.user.confirm_email') if params[:user][:email] && @user.email != params[:user][:email]
        format.turbo_stream
        format.html do
          if params[:back] == 'home'
            redirect_to home_url
          else
            redirect_back(fallback_location: root_path)
          end
        end
      else
        @user.errors.full_messages.each do |msg|
          flash[:error] = msg
        end
        format.turbo_stream { render partial: 'layouts/flash_stream', status: :unprocessable_entity }
        format.html do
          if params[:back] == 'home'
            redirect_to home_url
          else
            redirect_back(fallback_location: root_path)
          end
        end
      end
    end
  end

  def show_message
    authorize! :send_message, @user
    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  # Invia un messaggio privato via email (non c'è inbox interna — solo email diretta).
  # `deliver_later` usa Solid Queue — il job è in coda `mailers` per non bloccare la request.
  def send_message
    authorize! :send_message, @user
    ResqueMailer.user_message(params[:message][:subject], params[:message][:body], current_user.id, @user.id).deliver_later
    flash[:notice] = t('info.message_sent')
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @user }
    end
  end

  # Autocomplete utenti nell'ambito dei partecipanti di un gruppo specifico.
  # Usato nei form di assegnazione ruoli/aree dove ha senso cercare solo membri del gruppo.
  def autocomplete
    @group = Group.friendly.find(params[:group_id])
    users = @group.participants.autocomplete(params[:term])
    users = users.map do |u|
      { id: u.id, identifier: "#{u.surname} #{u.name}", image_path: avatar(u, size: 20).to_s }
    end
    render json: users
  end

  protected

  # Pattern comune per le azioni di preferenza utente.
  # Turbo Stream: flash in-page. HTML: redirect back (restando sulla stessa pagina di preferenze).
  def respond_to_preference
    respond_to do |format|
      format.turbo_stream { render partial: 'layouts/flash_stream' }
      format.html { redirect_back fallback_location: root_path }
    end
  end

  # Valida i parametri di join_accounts: la password non può essere vuota.
  # `empty?` invece di `blank?` perché nil sarebbe già gestito da strong parameters.
  # @return [Boolean]
  def wrong_join_accounts_params?
    params[:user][:password].empty?
  end

  def user_params
    params.require(:user).permit(:name, :email, :surname, :password, :password_confirmation, :sex, :remember_me,
                                 :accept_conditions, :receive_newsletter, :sys_locale_id, :time_zone, :avatar,
                                 :interest_borders_tokens)
  end

  def choose_layout
    if ['index'].include? action_name
      'open_space'
    elsif ['confirm_credentials'].include? action_name
      'application'
    else
      'users'
    end
  end

  def load_user
    @user = User.find(params[:id])
  end
end
