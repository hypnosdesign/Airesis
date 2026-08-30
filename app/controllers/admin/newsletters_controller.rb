module Admin
  class NewslettersController < Admin::ApplicationController
    load_and_authorize_resource

    def index; end

    def show; end

    def new; end

    def edit; end

    def create
      if @newsletter.save
        redirect_to edit_admin_newsletter_path(@newsletter), status: :see_other
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @newsletter.update(newsletter_params)
        redirect_to edit_admin_newsletter_path(@newsletter), status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def preview
      @user = User.new(name: Faker::Name.name, surname: Faker::Name.last_name, original_locale: SysLocale.all.sample)
      @page_title = "#{@newsletter.subject} — #{t('buttons.preview')}"
      @newsletter_body = view_context.sanitize(@newsletter.body)
      render :preview, layout: 'newsletters/default'
    end

    def publish
      count = @newsletter.publish(receiver: newsletter_params[:receiver], test_user_id: current_user.id)
      flash[:notice] = t('admin_ui.newsletters.queued', count: count)
      redirect_back fallback_location: admin_newsletter_path(@newsletter), status: :see_other
    rescue ArgumentError
      flash.now.alert = 'Seleziona un gruppo di destinatari valido'
      render :show, status: :unprocessable_content
    end

    def destroy
      @newsletter.destroy!
      redirect_to admin_newsletters_path, notice: 'Newsletter eliminata', status: :see_other
    end

    protected

    def newsletter_params
      params.require(:newsletter).permit(:subject, :body, :receiver)
    end
  end
end
