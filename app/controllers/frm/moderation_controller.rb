module Frm
  class ModerationController < Frm::ApplicationController
    before_action :ensure_moderator_or_admin

    helper 'frm/posts'

    def index
      @posts = forum.posts.pending_review.topic_not_pending_review
      @topics = forum.topics.pending_review
    end

    def posts
      Frm::Post.moderate!(moderation_params, scope: forum.posts)
      flash[:notice] = t('frm.posts.moderation.success')
      redirect_to group_frm_forum_moderator_tools_path(@group, forum), status: :see_other
    rescue ActiveRecord::RecordNotFound, ArgumentError
      flash[:alert] = t('frm.posts.moderation.invalid')
      redirect_to group_frm_forum_moderator_tools_path(@group, forum), status: :see_other
    end

    def topic
      if params[:frm_topic]
        topic = forum.topics.friendly.find(params.expect(:topic_id))
        topic.moderate!(topic_moderation_params.fetch(:moderation_option))
        flash[:notice] = t('frm.topic.moderation.success')
      else
        flash[:alert] = t('frm.topic.moderation.no_option_selected')
      end
      redirect_to group_forum_topic_path(@group, forum, topic || params[:topic_id]), status: :see_other
    rescue ActiveRecord::RecordNotFound, ActionController::ParameterMissing, ArgumentError
      flash[:alert] = t('frm.topic.moderation.no_option_selected')
      redirect_to group_frm_forum_moderator_tools_path(@group, forum), status: :see_other
    end

    private

    def forum
      @forum = @group.forums.friendly.find(params.expect(:forum_id))
    end

    helper_method :forum

    def ensure_moderator_or_admin
      raise CanCan::AccessDenied unless forem_admin?(@group) || forum.moderator?(current_user)
    end

    def moderation_params
      submitted_posts = params.fetch(:posts, ActionController::Parameters.new)
      submitted_posts.keys.each_with_object({}) do |post_id, allowed|
        next unless post_id.to_s.match?(/\A\d+\z/)

        attributes = submitted_posts[post_id]
        allowed[post_id] = attributes.permit(:moderation_option).to_h
      end
    end

    def topic_moderation_params
      params.expect(frm_topic: [:moderation_option])
    end
  end
end
