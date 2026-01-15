require_relative "javascript_parsing"

module InertiaI18n
  module Parsers
    class SvelteParser < BaseParser
      include JavascriptParsing

      def extract_keys_from_content(content)
        # Svelte files are a mix of HTML and JS.
        # Our improved JavascriptParsing is now robust enough to find t()
        # calls anywhere in the file (script or template).
        extract_javascript_keys(content)
      end
    end
  end
end
