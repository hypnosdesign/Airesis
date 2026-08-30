class BlogCommentsController < ApplicationController
  before_action :save_comment, only: :create
  before_action :authenticate_user!
  before_action :load_comment_context
  before_action :load_blog_comment, only: :destroy

  def create
    @blog_comment = @blog_post.blog_comments.build(blog_comment_params)
    authorize! :create, @blog_comment

    respond_to do |format|
      if save_blog_comment(@blog_comment)
        flash[:notice] = t('info.blog.comment_added')
        @blog_comment.collapsed = true
        format.html { redirect_to blog_post_destination, status: :see_other }
        format.turbo_stream
      else
        flash[:error] = t('error.blog.comment_added')
        prepare_post_view
        format.html { render 'blog_posts/show', status: :unprocessable_content, layout: (@group ? 'groups' : 'users') }
        format.turbo_stream { render 'blog_comments/errors/create', status: :unprocessable_content }
      end
    end
  end

  def destroy
    authorize! :destroy, @blog_comment
    @blog_comment.destroy
    flash[:notice] = t('info.blog_comment.destroyed')
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to blog_post_destination, status: :see_other }
    end
  end

  private

  def blog_comment_params
    params.require(:blog_comment).permit(:parent_blog_comment_id, :body)
  end

  def load_comment_context
    @group = Group.friendly.find(params[:group_id]) if params[:group_id].present?
    @blog = Blog.friendly.find(params[:blog_id]) if params[:blog_id].present?
    scope = @group ? @group.blog_posts : @blog.blog_posts
    @blog_post = scope.find(params[:blog_post_id])
    @blog ||= @blog_post.blog
    authorize! :read, @group if @group
    authorize! :read, @blog
  end

  def load_blog_comment
    @blog_comment = @blog_post.blog_comments.find(params[:id])
  end

  def blog_post_destination
    @group ? group_blog_post_url(@group, @blog_post) : blog_blog_post_url(@blog, @blog_post)
  end

  def prepare_post_view
    @page_title = @blog_post.title
    @blog_url = blog_post_destination
    @user = @blog_post.user
    @pagy, @blog_comments = pagy(:offset, @blog_post.blog_comments.includes(user: [:image]).order(created_at: :desc), limit: COMMENTS_PER_PAGE)
  end

  def save_comment
    return if current_user

    session[:blog_comment] = blog_comment_params
    session[:blog_post_id] = params[:blog_post_id]
    session[:blog_id] = params[:blog_id]
    flash[:info] = t('info.proposal.login_to_contribute')
  end
end
