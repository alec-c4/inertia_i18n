# frozen_string_literal: true

require_relative "javascript_parsing"

module InertiaI18n
  module Parsers
    class VueParser < BaseParser
      include JavascriptParsing

      def extract_keys_from_content(content)
        # Use common JS parsing for everything first

        result = extract_javascript_keys(content)

        # Add Vue-specific v-t directive support

        vt_keys = extract_vt_directive_keys(content)

        {

          static: (result[:static] + vt_keys).uniq,

          dynamic: result[:dynamic]

        }
      end

      private

      def extract_vt_directive_keys(content)
        keys = []

        # v-t directive: v-t="'key'" or v-t='"key"'

        content.scan(/v-t\s*=\s*(["'])['"]([^'"]+)['"]\1/) do |match|
          keys << match[1]
        end

        keys
      end
    end
  end
end
