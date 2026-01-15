# frozen_string_literal: true

require "json"

module InertiaI18n
  class LocaleLoader
    class << self
      def load_all
        config = InertiaI18n.configuration
        locales = {}

        config.locales.each do |locale|
          file = File.join(config.target_path, "#{locale}.json")
          if File.exist?(file)
            locales[locale] = JSON.parse(File.read(file))
          else
            warn "Warning: Locale file not found: #{file}"
            locales[locale] = {}
          end
        end

        locales
      end

      def extract_keys(data, prefix = "")
        keys = []

        data.each do |key, value|
          current_path = prefix.empty? ? key : "#{prefix}.#{key}"

          if value.is_a?(Hash)
            keys.concat(extract_keys(value, current_path))
          else
            keys << current_path
          end
        end

        keys
      end
    end
  end
end
