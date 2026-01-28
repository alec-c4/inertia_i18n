# frozen_string_literal: true

require "yaml"
require "json"

module InertiaI18n
  class Normalizer
    def normalize
      normalize_json_files
      normalize_yaml_files
    end

    private

    def normalize_json_files
      config = InertiaI18n.configuration

      config.locales.each do |locale|
        file = File.join(config.target_path, "#{locale}.json")
        next unless File.exist?(file)

        data = JSON.parse(File.read(file))
        sorted_data = deep_sort(data)
        File.write(file, JSON.pretty_generate(sorted_data) + "\n")

        puts "Normalized #{file}"
      end
    end

    def normalize_yaml_files
      config = InertiaI18n.configuration

      yaml_files = config.source_paths.flat_map do |path|
        Dir.glob(File.join(path, config.source_pattern))
      end.uniq

      yaml_files.each do |file|
        next unless File.exist?(file)

        begin
          data = YAML.load_file(file, permitted_classes: [Symbol])
          next unless data

          sorted_data = deep_sort(data)

          File.write(file, sorted_data.to_yaml)
          puts "Normalized #{file}"
        rescue Psych::SyntaxError => e
          warn "Warning: Failed to parse #{file}: #{e.message}"
        end
      end
    end

    def deep_sort(data)
      case data
      when Hash
        data.keys.sort.each_with_object({}) do |key, sorted|
          sorted[key] = deep_sort(data[key])
        end
      when Array
        data.map { |item| deep_sort(item) }
      else
        data
      end
    end
  end
end
