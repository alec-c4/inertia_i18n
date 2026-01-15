# frozen_string_literal: true

module InertiaI18n
  module Parsers
    class BaseParser
      def initialize
        @config = InertiaI18n.configuration
      end

      def extract_keys(file_path)
        content = File.read(file_path)
        extract_keys_from_content(content)
      end

      def extract_keys_from_content(content)
        raise NotImplementedError, "#{self.class.name} must implement a `extract_keys_from_content` method."
      end
    end
  end
end
