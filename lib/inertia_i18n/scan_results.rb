# frozen_string_literal: true

module InertiaI18n
  class ScanResults
    attr_reader :files, :static_keys, :dynamic_patterns, :occurrences

    def initialize
      @files = {}
      @static_keys = Set.new
      @dynamic_patterns = []
      @occurrences = Hash.new { |h, k| h[k] = [] }
    end

    def add_file(file, keys)
      @files[file] = keys

      keys[:static].each do |usage|
        # Handle both legacy string keys and new usage objects
        if usage.is_a?(Hash)
          key = usage[:key]
          @static_keys.add(key)
          @occurrences[key] << {file: file, line: usage[:line]}
        else
          @static_keys.add(usage)
          @occurrences[usage] << {file: file, line: nil}
        end
      end

      config = InertiaI18n.configuration
      dynamic_keys_config = config.dynamic_keys || {}

      keys[:dynamic].each do |dynamic|
        pattern = dynamic[:pattern]
        @dynamic_patterns << dynamic

        if dynamic_keys_config.key?(pattern)
          dynamic_keys_config[pattern].each do |value|
            # Append value to pattern (e.g. "status." + "active" -> "status.active")
            expanded_key = "#{pattern}#{value}"
            @static_keys.add(expanded_key)
            @occurrences[expanded_key] << {file: file, line: dynamic[:line]}
          end
        end
      end
    end

    def used_keys
      @static_keys
    end

    def to_h
      {
        files: @files,
        static_keys: @static_keys.to_a,
        dynamic_patterns: @dynamic_patterns,
        occurrences: @occurrences
      }
    end
  end
end
