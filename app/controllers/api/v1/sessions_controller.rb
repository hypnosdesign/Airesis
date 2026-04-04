module Api
  module V1
    class SessionsController < Devise::SessionsController
      respond_to :json
      skip_before_action :verify_authenticity_token, if: :json_request?

      before_action :authenticate_user_from_token!, only: [:destroy]

      def create
        warden.authenticate!(scope: resource_name)
        @user = current_user
      end

      def destroy
        if user_signed_in?
          @user = current_user
          @user.authentication_token = nil
          @user.save
        else
          render :failure
        end
      end

      private

      def authenticate_user_from_token!
        token = request.headers['X-User-Token']
        email = request.headers['X-User-Email']
        user = email.present? && User.find_by(email: email)
        if user && user.authentication_token.present? &&
           ActiveSupport::SecurityUtils.secure_compare(user.authentication_token, token.to_s)
          sign_in user, store: false
        end
      end

      def json_request?
        request.format.json?
      end
    end
  end
end
