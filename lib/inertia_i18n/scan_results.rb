# frozen_string_literal: true

module InertiaI18n
  class ScanResults
    attr_reader :files, :static_keys, :dynamic_patterns

    def initialize
      @files = {}
      @static_keys = Set.new
      @dynamic_patterns = []
    end

    def add_file(file, keys)
      @files[file] = keys
      keys[:static].each { |key| @static_keys.add(key) }
      @dynamic_patterns.concat(keys[:dynamic])
    end

    def used_keys
      @static_keys
    end

    def to_h
      {
        files: @files,
        static_keys: @static_keys.to_a,
        dynamic_patterns: @dynamic_patterns
      }
    end
  end
end
