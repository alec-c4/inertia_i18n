# frozen_string_literal: true

module InertiaI18n
  class Scanner
    def initialize(config = InertiaI18n.configuration)
      @config = config
    end

    def scan
      results = ScanResults.new

      frontend_files.each do |file|
        parser = parser_for_file(file)
        keys = parser.extract_keys(file)
        results.add_file(file, keys)
      end

      results
    end

    private

    def frontend_files
      @config.scan_paths.flat_map { |pattern| Dir.glob(pattern) }
    end

    def parser_for_file(file)
      ext = File.extname(file).downcase

      case ext
      when ".svelte"
        Parsers::SvelteParser.new
      when ".vue"
        Parsers::VueParser.new
      when ".jsx", ".tsx"
        Parsers::ReactParser.new
      when ".js", ".ts"
        Parsers::JavaScriptParser.new
      else
        Parsers::BaseParser.new
      end
    end
  end
end
