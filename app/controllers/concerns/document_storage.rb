module DocumentStorage
  extend ActiveSupport::Concern

  INLINE_DOCUMENT_EXTENSIONS = %w[.csv .gif .jpeg .jpg .pdf .png .txt .webp].freeze

  private

  def document_root
    storage_root = ENV.fetch('DOCUMENTS_STORAGE_ROOT', Rails.root.join('private/elfinder').to_s)
    @document_root ||= Pathname(storage_root).join(@group.id.to_s).cleanpath
  end

  def document_files
    return [] unless document_root.directory?

    documents = document_root.glob('**/*').filter_map do |path|
      relative_path = path.relative_path_from(document_root).to_s
      safe_path = resolve_document(relative_path)
      next unless safe_path&.file?

      {
        path: relative_path,
        name: safe_path.basename.to_s,
        bytes: safe_path.size,
        updated_at: safe_path.mtime
      }
    end
    documents.sort_by { |document| document[:name].downcase }
  end

  def resolve_document(relative_path)
    return if relative_path.blank?
    return unless document_root.directory?

    candidate = document_root.join(relative_path.to_s).cleanpath
    return unless candidate.to_s.start_with?("#{document_root}/")

    resolved_root = document_root.realpath
    resolved_candidate = candidate.realpath
    return unless resolved_candidate.to_s.start_with?("#{resolved_root}/")

    resolved_candidate
  rescue Errno::EACCES, Errno::ENOENT, Errno::ENOTDIR, Errno::ELOOP
    nil
  end

  def sanitize_filename(filename)
    File.basename(filename.to_s).unicode_normalize(:nfc).gsub(/[^\p{Alnum}. _-]/, '_').strip
  end

  def sync_storage_usage!
    used_kilobytes = storage_usage_kilobytes
    @group.update!(actual_storage_size: used_kilobytes) if @group.actual_storage_size != used_kilobytes
  end

  def storage_usage_kilobytes
    document_files.sum { |document| (document[:bytes].to_f / 1024).ceil }
  end

  def safe_inline_document?(file)
    INLINE_DOCUMENT_EXTENSIONS.include?(file.extname.downcase)
  end
end
