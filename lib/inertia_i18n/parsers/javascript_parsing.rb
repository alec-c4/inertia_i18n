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
          # Uses lookbehind (?<![\w]) to ensure we don't match end of other words (e.g. split)
          content.scan(/(?<!\w)#{escaped_func}\(\s*(['"`])([^'"`]+)\1/) do |match|
            quote_type, key = match

            # If it's a backtick, ensure it's not a template literal with interpolation

            next if quote_type == "`" && key.include?("${")

            keys << key
          end
        end

        # Extract keys from object properties (e.g., titleKey: "some.key")
        config.key_properties.each do |prop|
          # Matches: titleKey: "some.key" or titleKey: 'some.key'
          content.scan(/#{Regexp.escape(prop)}\s*:\s*(['"])([^'"]+)\1/) do |_quote, key|
            keys << key if looks_like_i18n_key?(key)
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
          content.scan(/(?<!\w)#{escaped_func}\(\s*`([^`]*\$\{.+?)`/) do |match|
            template = match[0]
            prefix = template.split("${").first
            patterns << {pattern: prefix, type: :template_literal, raw: template}
          end

          # Matches t('prefix.' + var) or t("prefix." + var) - string concatenation
          content.scan(/(?<!\w)#{escaped_func}\(\s*(['"])([^'"]+\.)\1\s*\+/) do |match|
            prefix = match[1]
            patterns << {pattern: prefix, type: :string_concat, raw: "#{prefix} + ..."}
          end
        end

        patterns
      end

      private

      # Check if a string looks like an i18n key (has dots, proper length, not a URL)
      def looks_like_i18n_key?(key)
        return false if key.nil? || key.empty?
        return false if key.length < 4
        return false unless key.include?(".")
        return false if key.start_with?("/")
        return false if key.match?(/^https?:/)
        return false if key.match?(/\s/) # Contains whitespace
        true
      end
    end
  end
end
