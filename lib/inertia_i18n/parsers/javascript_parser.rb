# frozen_string_literal: true

require_relative "javascript_parsing"

module InertiaI18n
  module Parsers
    class JavaScriptParser < BaseParser
      include JavascriptParsing

      # JavaScript/TypeScript parser
      def extract_keys_from_content(content)
        extract_javascript_keys(content)
      end
    end
  end
end
