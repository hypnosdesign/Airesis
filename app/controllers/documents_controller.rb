class DocumentsController < ApplicationController
  include DocumentStorage

  layout 'groups'

  before_action :load_group
  before_action :authenticate_user!
  before_action :authorize_document_access

  def index
    @documents = document_files
    @current_storage_size = storage_usage_kilobytes
  end

  def view
    file = resolve_document(params[:path])
    return head :not_found unless file&.file?

    disposition = params[:download].present? || !safe_inline_document?(file) ? 'attachment' : 'inline'
    send_file file,
              disposition: disposition,
              filename: file.basename.to_s
  end

  def upload
    authorize! :manage_documents, @group
    uploaded_file = params[:document]

    if uploaded_file.blank?
      redirect_to group_documents_path(@group),
                  alert: t('pages.groups.documents.upload_missing'),
                  status: :see_other
      return
    end

    filename = sanitize_filename(uploaded_file.original_filename)
    destination = document_root.join(filename)
    current_bytes = document_files.sum { |document| document[:bytes] }
    maximum_bytes = @group.max_storage_size.to_i.kilobytes

    if filename.blank? || destination.exist?
      redirect_to group_documents_path(@group),
                  alert: t('pages.groups.documents.upload_duplicate'),
                  status: :see_other
    elsif maximum_bytes.positive? && current_bytes + uploaded_file.size > maximum_bytes
      redirect_to group_documents_path(@group),
                  alert: t('pages.groups.documents.upload_too_large'),
                  status: :see_other
    else
      FileUtils.mkdir_p(document_root)
      File.open(destination, 'wb') { |file| IO.copy_stream(uploaded_file.tempfile, file) }
      sync_storage_usage!
      redirect_to group_documents_path(@group),
                  notice: t('pages.groups.documents.uploaded', filename: filename),
                  status: :see_other
    end
  end

  def remove
    authorize! :manage_documents, @group
    file = resolve_document(params[:path])
    return head :not_found unless file&.file?

    filename = file.basename.to_s
    File.delete(file)
    sync_storage_usage!
    redirect_to group_documents_path(@group),
                notice: t('pages.groups.documents.removed', filename: filename),
                status: :see_other
  end

  private

  def authorize_document_access
    authorize! :view_data, @group
    authorize! :view_documents, @group
  end
end
