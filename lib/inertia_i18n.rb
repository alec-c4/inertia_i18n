# frozen_string_literal: true

require_relative "inertia_i18n/version"
require_relative "inertia_i18n/configuration"
require_relative "inertia_i18n/converter"
require_relative "inertia_i18n/scan_results"
require_relative "inertia_i18n/parsers/base_parser"
require_relative "inertia_i18n/parsers/javascript_parser"
require_relative "inertia_i18n/parsers/svelte_parser"
require_relative "inertia_i18n/parsers/react_parser"
require_relative "inertia_i18n/parsers/vue_parser"
require_relative "inertia_i18n/scanner"
require_relative "inertia_i18n/locale_loader"
require_relative "inertia_i18n/file_converter"
require_relative "inertia_i18n/health_checker"

module InertiaI18n
  class Error < StandardError; end
end
