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

    # Object properties that contain translation keys (e.g., titleKey: "some.key")
    attr_accessor :key_properties

    # Sibling detection settings for enum-like keys (status, types, etc.)
    attr_accessor :sibling_detection

    # Filters for false-positive missing keys
    attr_accessor :missing_key_filters

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
      @key_properties = %w[titleKey labelKey messageKey descriptionKey placeholderKey key]
      @sibling_detection = {
        enabled: true,
        suffixes: %w[status statuses types type priorities priority]
      }
      @missing_key_filters = {
        min_length: 4,
        require_dot: true,
        exclude_patterns: [
          /^\/[\w\/-]*$/,           # URL paths (/hr/applications)
          /^[A-Z_]+$/,               # Constants (HTTP, POST)
          /^\w+_id$/,                # ID fields (user_id, parent_id)
          /^[a-z]{2}(-[A-Z]{2})?$/   # Locales (en, ru-RU)
        ]
      }
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
