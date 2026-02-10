# frozen_string_literal: true

require "yaml"

module InertiaI18n
  class Configuration
    # Source paths for Rails YAML locale files. Can be one or more directories.
    attr_accessor :source_paths

    # Target path for generated i18next JSON files
    attr_accessor :target_path

    # Locales to process (first is primary)
    attr_writer :locales

    def locales
      @locales || I18n.available_locales
    end

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
      @locales = nil # Uses I18n.available_locales by default
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

    def load_from_yaml(path)
      data = YAML.safe_load_file(path, permitted_classes: [Regexp])
      return unless data.is_a?(Hash)

      SIMPLE_ATTRIBUTES.each do |attr|
        public_send(:"#{attr}=", data[attr.to_s]) if data.key?(attr.to_s)
      end

      self.locales = data["locales"].map(&:to_sym) if data.key?("locales")

      load_hash_attribute(:interpolation, data)
      self.dynamic_patterns = data["dynamic_patterns"] || {} if data.key?("dynamic_patterns")
      load_sibling_detection(data) if data.key?("sibling_detection")
      load_missing_key_filters(data) if data.key?("missing_key_filters")
    end

    private

    SIMPLE_ATTRIBUTES = %i[
      source_paths target_path source_pattern scan_paths
      translation_functions ignore_unused ignore_missing key_properties
    ].freeze

    def load_hash_attribute(attr, data)
      return unless data.key?(attr.to_s)

      raw = data[attr.to_s]
      public_send(:"#{attr}=", symbolize_keys(raw))
    end

    def load_sibling_detection(data)
      raw = data["sibling_detection"]
      self.sibling_detection = {
        enabled: raw.fetch("enabled", true),
        suffixes: raw.fetch("suffixes", [])
      }
    end

    def load_missing_key_filters(data)
      raw = data["missing_key_filters"]
      self.missing_key_filters = {
        min_length: raw.fetch("min_length", 4),
        require_dot: raw.fetch("require_dot", true),
        exclude_patterns: (raw["exclude_patterns"] || []).map { |p| Regexp.new(p) }
      }
    end

    def symbolize_keys(hash)
      return hash unless hash.is_a?(Hash)

      hash.each_with_object({}) do |(k, v), result|
        result[k.to_sym] = v.is_a?(Hash) ? symbolize_keys(v) : v
      end
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
