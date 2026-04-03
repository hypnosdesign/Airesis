# Exclude lib subdirectories that don't follow Zeitwerk naming conventions
# (loaded explicitly via require, not via autoloading)
Rails.autoloaders.each do |autoloader|
  autoloader.ignore("#{Rails.root}/lib/rails_admin")
end
