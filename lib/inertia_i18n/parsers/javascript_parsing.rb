# frozen_string_literal: true

module InertiaI18n
  module Parsers
    # A mixin for parsers that need to extract translation keys
    # from JavaScript-like content.
    module JavascriptParsing
      protected

      def extract_javascript_keys(content)
        {
          static: extract_static_keys(content).uniq,
          dynamic: extract_dynamic_patterns(content).uniq { |p| p[:pattern] }
        }
      end

      def extract_static_keys(content)
        keys = []

        config = InertiaI18n.configuration

        config.translation_functions.each do |func|
          escaped_func = Regexp.escape(func)

          # Matches t('key'), t("key"), t(`key`)

          # Uses a lookahead to ensure it's a translation function call

          content.scan(/#{escaped_func}\(\s*(['"`])([^'"`]+)\1/) do |match|
            quote_type, key = match

            # If it's a backtick, ensure it's not a template literal with interpolation

            next if quote_type == "`" && key.include?("${")

            keys << key
          end
        end

        keys
      end

      def extract_dynamic_patterns(content)
        patterns = []

        config = InertiaI18n.configuration

        config.translation_functions.each do |func|
          escaped_func = Regexp.escape(func)

          # Matches t(`prefix.${var}`)

          content.scan(/#{escaped_func}\(\s*`([^`]*\$\{.+?)`/) do |match|
            template = match[0]

            prefix = template.split("${").first

            patterns << {pattern: prefix, type: :template_literal, raw: template}
          end
        end

        patterns
      end
    end
  end
end
