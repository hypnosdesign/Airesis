class DocumentsController < ApplicationController
  layout 'groups'

  before_action :load_group, except: [:view]
  before_action :authenticate_user!

  def index
    authorize! :view_data, @group
    authorize! :view_documents, @group
  end

  def view
    raw_url = params[:url].to_s
    group_id = raw_url[%r{\A/private/elfinder/([^/]+)/}, 1]

    return head :bad_request if group_id.blank?

    @group = Group.find_by(id: group_id)
    return render_404 if @group.nil?

    authorize! :view_documents, @group

    # Prevent path traversal: resolve and verify path stays inside group's directory
    allowed_root = Rails.root.join('private', 'elfinder', @group.id.to_s).cleanpath
    requested_path = Rails.root.join(raw_url.delete_prefix('/')).cleanpath

    return head :forbidden unless requested_path.to_s.start_with?(allowed_root.to_s + '/')

    if params[:download]
      send_file requested_path
    else
      send_file requested_path, disposition: 'inline'
    end
  end
end
