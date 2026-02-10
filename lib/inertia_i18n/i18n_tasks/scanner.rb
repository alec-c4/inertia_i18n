# frozen_string_literal: true

require "i18n/tasks/scanners/file_scanner"
require "i18n/tasks/scanners/results/occurrence"

module InertiaI18n
  module I18nTasks
    class Scanner < ::I18n::Tasks::Scanners::FileScanner
      def scan_file(path)
        # Scan file using InertiaI18n logic
        scanner = InertiaI18n::Scanner.new
        parser = scanner.parser_for_file(path)
        return [] unless parser
        return [] if parser.instance_of?(InertiaI18n::Parsers::BaseParser)

        # Extract keys: {static: [{key: 'foo', line: 1}], dynamic: [...]}
        results = parser.extract_keys(path)

        # Convert to i18n-tasks format: [ [key, Occurrence] ]
        results[:static].map do |usage|
          key = usage[:key]

          # Return the format i18n-tasks expects for key occurrences
          [
            key,
            ::I18n::Tasks::Scanners::Results::Occurrence.new(
              path: path,
              line_num: usage[:line],
              pos: 1,
              line_pos: 1,
              line: "",
              raw_key: key
            )
          ]
        end
      end
    end
  end
end
