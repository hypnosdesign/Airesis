ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "logger" # needed before bootsnap/setup with bootsnap >= 1.10 + Rails 6.1
require "bootsnap/setup" # Speed up boot time by caching expensive operations.

# Psych 4.0+ (Ruby 3.1+) disabled YAML aliases by default.
# Webpacker 5.x and other legacy gems load YAML files with anchors/aliases
# without passing aliases: true. Re-enable aliases globally for compatibility.
# Remove this patch once Webpacker is replaced (Phase 3).
require "psych"
module Psych
  class << self
    alias_method :load_without_alias_compat, :load
    def load(yaml, permitted_classes: [], permitted_symbols: [], aliases: true, filename: nil, fallback: nil, symbolize_names: false, freeze: false)
      load_without_alias_compat(yaml, permitted_classes: permitted_classes, permitted_symbols: permitted_symbols, aliases: aliases, filename: filename, fallback: fallback, symbolize_names: symbolize_names, freeze: freeze)
    end
  end
end
