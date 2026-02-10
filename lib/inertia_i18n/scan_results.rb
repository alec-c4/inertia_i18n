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

      @dynamic_patterns.concat(keys[:dynamic])
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
