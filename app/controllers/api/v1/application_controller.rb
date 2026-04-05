module Api
  module V1
    class ApplicationController < ActionController::Base
      include Pagy::Backend

      before_action :authenticate_user_from_token!

      protect_from_forgery with: :null_session
      respond_to :json

      rescue_from ActiveRecord::RecordNotFound, with: :render_404
      rescue_from CanCan::AccessDenied, with: :render_401

      protected

      def authenticate_user_from_token!
        token = request.headers['X-User-Token']
        email = request.headers['X-User-Email']
        user = email.present? && User.find_by(email: email)
        if user && user.authentication_token.present? &&
           ActiveSupport::SecurityUtils.secure_compare(user.authentication_token, token.to_s)
          sign_in user, store: false
        end
      end

      def render_401
        render json: { error_key: :unauthorized }, status: :unauthorized
      end

      def render_404
        render json: { error_key: :not_found }, status: :not_found
      end
    end
  end
end
