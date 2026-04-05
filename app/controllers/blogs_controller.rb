class BlogsController < ApplicationController
  layout :choose_layout

  load_and_authorize_resource

  before_action :load_blog_data, only: %i[show edit by_year_and_month]

  def index
    @tags = Tag.most_blogs(current_domain.territory).shuffle unless request.xhr?
    @page_title = t('pages.blogs.show.title')

    params[:interest_border] ||= InterestBorder.to_key(current_domain.territory)
    @pagy, @blogs = pagy(Blog.look(params), items: 30)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    @page_title = @blog.title
    @pagy, @blog_posts = pagy(@blog_posts.published, items: COMMENTS_PER_PAGE)
    respond_to do |format|
      format.html
      format.turbo_stream
      format.atom
    end
  end

  def by_year_and_month
    @page_title = t('pages.blog_posts.archives.title', year: params[:year], month: t('calendar.monthNames')[params[:month].to_i - 1])
    @pagy, @blog_posts = pagy(@blog_posts.published.where('extract(year from created_at) = ? AND extract(month from created_at) = ? ', params[:year], params[:month]).order('created_at DESC'), items: COMMENTS_PER_PAGE)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def new
    if current_user.blog
      flash[:error] = t('error.blog.already_have')
      redirect_to root_path
    else
      @user = current_user
      @blog.user = current_user
      @page_title = t('pages.blogs.new.title')
    end
  end

  def edit
    @user = @blog.user
  end

  def create
    @blog.user = current_user
    if @blog.save
      flash[:notice] = t('info.blog.blog_created')
      if session[:blog_return_to]
        redirect_to session[:blog_return_to]
      else
        redirect_to @blog
      end
    else
      @user = current_user
      render action: 'new'
    end
  end

  def update
    if @blog.update(blog_params)
      flash[:notice] = t('info.blog.title_updated')
      redirect_to @blog
    else
      render action: 'edit'
    end
  end

  def destroy
    @blog = Blog.friendly.find(params[:id])
    @blog.destroy
    flash[:notice] = t('info.blog.destroyed')
    redirect_to root_path
  end

  protected

  def blog_params
    params.require(:blog).permit(:title)
  end

  def load_blog
    @blog = Blog.friendly.find(params[:id])
  end

  def choose_layout
    params[:action] == 'index' ? 'open_space' : 'users'
  end
end
