# frozen_string_literal: true

require_relative "javascript_parsing"

module InertiaI18n
  module Parsers
    class ReactParser < BaseParser
      include JavascriptParsing

      # React/JSX/TSX parser
      def extract_keys_from_content(content)
        # The entire file is parsed as JavaScript
        extract_javascript_keys(content)
      end
    end
  end
end
