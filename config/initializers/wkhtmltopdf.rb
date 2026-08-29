WickedPdf.configure do |config|
  config.exe_path = ENV['WKHTMLTOPDF_PATH'] || `which wkhtmltopdf`.strip
end
