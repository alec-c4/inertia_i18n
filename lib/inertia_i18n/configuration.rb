# frozen_string_literal: true

module InertiaI18n
  class Configuration
    # Source paths for Rails YAML locale files. Can be one or more directories.
    attr_accessor :source_paths

    # Target path for generated i18next JSON files
    attr_accessor :target_path

    # Locales to process (first is primary)
    attr_accessor :locales

    # YAML file pattern to match
    attr_accessor :source_pattern

    # Interpolation conversion settings
    attr_accessor :interpolation

    # Paths to scan for translation usage
    attr_accessor :scan_paths

    # File extensions to scan by framework
    attr_accessor :scan_extensions

    # Translation function names to detect
    attr_accessor :translation_functions

    # Dynamic key patterns (prefix => regex)
    attr_accessor :dynamic_patterns

    # Keys to ignore during unused check
    attr_accessor :ignore_unused

    # Keys to ignore during missing check
    attr_accessor :ignore_missing

    def initialize
      @source_paths = ["config/locales/frontend"]
      @target_path = "app/frontend/locales"
      @locales = %i[en]
      @source_pattern = "**/*.{yml,yaml}"
      @interpolation = {from: "%{", to: "{{"}
      @scan_paths = ["app/frontend/**/*.{js,ts,jsx,tsx,svelte,vue}"]
      @scan_extensions = {
        svelte: %w[.svelte],
        react: %w[.jsx .tsx],
        vue: %w[.vue],
        javascript: %w[.js .ts]
      }
      @translation_functions = %w[t $t i18n.t]
      @dynamic_patterns = {}
      @ignore_unused = []
      @ignore_missing = []
    end

    def primary_locale
      locales.first
    end

    def secondary_locales
      locales[1..]
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
