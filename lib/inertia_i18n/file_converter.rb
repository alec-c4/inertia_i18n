# frozen_string_literal: true

require "yaml"
require "json"
require "fileutils"

module InertiaI18n
  class FileConverter
    class << self
      def convert_all
        config = InertiaI18n.configuration
        results = []

        config.locales.each do |locale|
          result = convert_locale(locale)
          results << result
        end

        results
      end

      def convert_locale(locale)
        config = InertiaI18n.configuration

        # Load all YAML files for this locale
        yaml_files = config.source_paths.flat_map do |path|
          Dir.glob(File.join(path, config.source_pattern))
        end
        merged_data = {}

        yaml_files.each do |file|
          data = YAML.load_file(file, permitted_classes: [Symbol])
          deep_merge!(merged_data, data) if data
        rescue Psych::SyntaxError => e
          warn "Warning: Failed to parse #{file}: #{e.message}"
        end

        # Convert to JSON
        converter = Converter.new(merged_data, locale: locale)
        json_data = converter.convert

        # Write JSON file
        output_file = File.join(config.target_path, "#{locale}.json")
        FileUtils.mkdir_p(config.target_path)
        File.write(output_file, JSON.pretty_generate(json_data) + "\n")

        {
          locale: locale,
          output_file: output_file,
          keys_count: LocaleLoader.extract_keys(json_data).size,
          source_files: yaml_files.size
        }
      end

      private

      def deep_merge!(target, source)
        source.each do |key, value|
          if target[key].is_a?(Hash) && value.is_a?(Hash)
            deep_merge!(target[key], value)
          else
            target[key] = value
          end
        end
        target
      end
    end
  end
end
