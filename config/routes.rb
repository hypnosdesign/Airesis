Rails.application.routes.draw do
  get '/validators/uniqueness/group/', to: 'validators/uniqueness#group'
  get '/validators/uniqueness/user/', to: 'validators/uniqueness#user'
  get '/validators/uniqueness/proposal/', to: 'validators/uniqueness#proposal'

  resources :searches, only: [:index]

  resources :sys_payment_notifications, only: [:create]

  resources :user_likes, only: %i[create destroy]

  resources :proposal_nicknames, only: [:update]

  get 'home' => 'home#show'
  get 'landing' => 'home#landing'
  get 'public' => 'home#public', as: :open_space
  get 'edemocracy' => 'home#intro'
  get 'eparticipation' => 'home#intro'
  get 'press' => 'home#press'
  get 'privacy' => 'home#privacy'
  get 'terms' => 'home#terms'
  get 'cookie_law' => 'home#cookie_law'
  post 'send_feedback' => 'home#feedback'
  get 'statistics' => 'home#statistics'
  get 'school' => 'home#school'
  get 'municipality' => 'home#municipality'

  resources :quorums, only: [] do
    collection do
      get :help
    end
  end

  resources :proposals do
    collection do
      get :endless_index
      get :similar
      get :tab_list
    end

    resources :proposal_comments, except: %i[new show] do
      member do
        put :rankup
        put :ranknil
        put :rankdown
        get :show_all_replies
        put :unintegrate
        get :history
      end
      collection do
        post :mark_noise
        get :list
        post :report
        get :noise
        get :manage_noise
      end
    end

    resources :proposal_revisions, only: %i[index show]
    resources :proposal_lives, only: :show
    resources :proposal_supports, only: %i[new create]
    resources :proposal_presentations, only: :destroy

    resources :blocked_proposal_alerts do
      collection do
        post :block
        post :unlock
      end
    end

    member do
      get :rankup
      get :rankdown
      patch :set_votation_date
      post :available_author
      get :available_authors_list
      put :add_authors
      get :vote_results
      post :close_debate
      post :start_votation
      patch :regenerate
      get :geocode
      get :promote
      get :banner
      get :test_banner
    end
  end

  resources :proposal_categories, only: [:index]

  resources :announcements, only: [] do
    post :hide, on: :member
  end

  resources :tutorials, only: [] do
    resources :steps, only: [] do
      member do
        get :complete
      end
    end
  end

  resources :alerts, only: [:index] do
    member do
      get :check
    end

    collection do
      get :proposal
      post :check_all
    end
  end

  resources :interest_borders, only: [:index], defaults: { format: :json }
  resources :municipalities, only: [:index], defaults: { format: :json }

  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks', sessions: 'sessions', registrations: 'registrations', passwords: 'passwords', confirmations: 'confirmations' } do
    get '/users/sign_in', to: 'devise/sessions#new'
    get '/users/sign_out', to: 'devise/sessions#destroy'
    get '/users/auth/:provider' => 'users/omniauth_callbacks#passthru'
  end

  resources :users, only: %i[index show edit update] do
    collection do
      get :confirm_credentials
      get :alarm_preferences
      get :border_preferences
      post :join_accounts
      get :privacy_preferences
      get :statistics
      post :change_show_tooltips
      post :change_show_urls
      post :change_receive_messages
      post :change_rotp_enabled
      post :change_locale
      post :change_time_zone
    end

    member do
      get :show_message
      post :send_message
    end

    resources :authentications
  end

  resources :notifications, only: [:index] do
    collection do
      post :change_notification_block
      post :change_email_notification_block
      post :change_email_block
    end
  end

  resources :blog_posts, only: %i[index show]

  resources :blogs do
    resources :blog_posts, only: %i[index new create show edit update destroy] do
      get :drafts, on: :collection
      resources :blog_comments, only: %i[create destroy]
    end
    get '/:year/:month' => 'blogs#by_year_and_month', as: :posts_by_year_and_month, on: :member
  end

  resources :tags, only: %i[index show]

  get '/votation', to: redirect('/public'), as: :legacy_votation
  put '/votation/vote', to: 'votations#vote', as: :votation_vote
  put '/votation/vote_schulze', to: 'votations#vote_schulze', as: :votation_vote_schulze

  concern :group_invitations do
    resources :group_invitations, only: %i[new create] do
      resources :group_invitation_emails, param: :token, only: [] do
        member do
          get :accept
          get :reject
          get :anymore
        end
      end
    end
  end

  concern :eventable do
    resources :events do
      member do
        post :move
        post :resize
      end
    end
  end

  concern :event_interactions do
    resources :events, only: [] do
      resources :meeting_participations, only: %i[create update]

      resources :event_comments, only: %i[create destroy] do
        post :like, on: :member
      end
    end
  end

  concern :participation_roles do
    resources :participation_roles, only: %i[index new create edit update destroy]
  end

  concerns :eventable
  concerns :event_interactions

  root to: 'home#index'
  namespace :api do
    namespace :v1 do
      resources :proposals, only: %i[show index]
      devise_scope :user do
        post 'login' => 'sessions#create', as: :login
      end
    end
  end

  resources :groups do
    member do
      post :ask_for_participation
      put :participation_request_confirm
      put :participation_request_decline
      post :change_default_anonima
      post :change_default_visible_outside
      post :change_advanced_options
      post :change_default_secret_vote
      get :reload_storage_size
      put :enable_areas
      put :remove_post
      put :feature_post
      get :permissions_list
    end

    collection do
      post :ask_for_multiple_follow
      get :autocomplete
    end

    resources :forums, controller: 'frm/forums', only: %i[index show] do
      resources :topics, controller: 'frm/topics', only: %i[new create show destroy] do
        member do
          post :subscribe
          get :unsubscribe, action: :unsubscribe_confirmation
          delete :unsubscribe
        end

        resources :posts, controller: 'frm/posts', only: %i[new create edit update destroy]
      end
    end

    namespace :frm do
      get 'forums/:forum_id/moderation', to: 'moderation#index', as: :forum_moderator_tools
      # For mass moderation of posts
      put 'forums/:forum_id/moderate/posts', to: 'moderation#posts', as: :forum_moderate_posts
      # Moderation of a single topic
      put 'forums/:forum_id/topics/:topic_id/moderate', to: 'moderation#topic', as: :moderate_forum_topic
      resources :categories, only: :show
      namespace :admin do
        root to: 'base#index'
        resources :mods, only: %i[index show new create destroy] do
          resources :members, only: [] do
            collection do
              post :add
            end
          end
        end

        resources :forums, except: :show do
          resources :topics, only: %i[edit update destroy] do
            member do
              put :toggle_hide
              put :toggle_lock
              put :toggle_pin
            end
          end
        end

        resources :categories, except: :show
      end
    end

    get 'users/autocomplete', to: 'users#autocomplete', as: 'user_autocomplete'

    concerns :eventable

    concerns :group_invitations

    resources :group_participations, only: %i[index destroy] do
      collection do
        post :send_email
        post :destroy_all
      end
      member do
        post :change_user_permission
      end
    end

    concerns :participation_roles

    resources :search_participants, only: :create

    resources :proposals do
      collection do
        get :search
      end
      member do
        post :close_debate
        post :start_votation
        patch :regenerate
        patch :set_votation_date
        get :geocode
        get :vote_results
      end
    end

    resources :quorums, only: :index do
      member do
        post :change_status
      end
    end

    resources :best_quorums, controller: 'quorums', only: %i[new create edit update destroy]

    resources :documents, only: :index do
      collection do
        get :view
        post :upload
        delete :remove
      end
    end

    resources :group_areas do
      resources :area_roles, only: %i[new create edit update destroy] do
        collection do
          put :change_permissions
        end
      end

      resources :area_participations, only: %i[create destroy]
    end

    resources :blog_posts, only: %i[index new create show edit update destroy] do
      resources :blog_comments, only: %i[create destroy]
    end

    get '/:year/:month' => 'groups#by_year_and_month', :as => :posts_by_year_and_month, on: :member
  end

  admin_required = lambda do |request|
    request.env['warden'].authenticate? && request.env['warden'].user.admin?
  end

  moderator_required = lambda do |request|
    request.env['warden'].authenticate? && request.env['warden'].user.moderator?
  end

  constraints moderator_required do
    get 'moderator_panel', to: 'admin/moderator#show', as: 'moderator/panel'
    namespace :admin do
      resources :users, only: [] do
        patch :unblock, on: :member
        collection do
          get :autocomplete
          post :block
        end
      end
    end
  end

  constraints admin_required do
    mount RailsAdmin::Engine => '/admin/data', as: 'rails_admin'

    namespace :admin do
      resources :newsletters do
        member do
          get :preview
          patch :publish
        end
      end
      # mount Sidekiq::Web => '/sidekiq' # removed: sidekiq replaced by solid_queue
      get '/', to: 'panel#show', as: 'panel'
      resource :panel, controller: 'panel', only: [] do
        post :calculate_rankings
        post :change_proposals_state
        post :write_sitemap
        post :delete_old_notifications
        post :test_mailer
        post :test_scheduler
        post :test_notification
      end
    end
  end

  resources :tokens, only: %i[create destroy]

  get '/:id' => 'groups#show'
end
