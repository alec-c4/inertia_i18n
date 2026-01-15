# frozen_string_literal: true

module InertiaI18n
  class Converter
    PLURAL_KEYS = %w[zero one two few many other].freeze

    def initialize(yaml_data, locale:)
      @yaml_data = yaml_data
      @locale = locale.to_s
      @config = InertiaI18n.configuration
    end

    def convert
      data = @yaml_data[@locale] || {}
      process(data)
    end

    private

    def process(obj, parent_key = nil)
      case obj
      when Hash
        process_hash(obj, parent_key)
      when String
        convert_interpolation(obj)
      when Array
        obj.map { |item| process(item) }
      else
        obj
      end
    end

    def process_hash(hash, parent_key)
      if pluralization_hash?(hash)
        process_pluralization(hash, parent_key)
      else
        result = {}
        hash.each do |key, value|
          processed = process(value, key)
          if processed.is_a?(Hash) && pluralization_result?(processed)
            result.merge!(processed)
          else
            result[key] = processed
          end
        end
        result
      end
    end

    def pluralization_hash?(hash)
      keys = hash.keys.map(&:to_s)
      (keys - PLURAL_KEYS).empty? && keys.any? { |k| PLURAL_KEYS.include?(k) }
    end

    def pluralization_result?(hash)
      hash.keys.all? { |k| k.to_s.match?(/_(?:zero|one|two|few|many|other)$/) }
    end

    def process_pluralization(hash, parent_key)
      result = {}
      hash.each do |plural_key, value|
        new_key = parent_key ? "#{parent_key}_#{plural_key}" : plural_key.to_s
        result[new_key] = process(value)
      end
      result
    end

    def convert_interpolation(string)
      to_prefix = @config.interpolation[:to]

      # Determine closing bracket based on prefix
      # {{ -> }}, ${ -> }
      to_suffix = to_prefix.end_with?("{{") ? "}}" : "}"

      # Match %{var} and convert to {{var}} (or custom format)
      string.gsub(/%\{(\w+)\}/, "#{to_prefix}\\1#{to_suffix}")
    end
  end
end
