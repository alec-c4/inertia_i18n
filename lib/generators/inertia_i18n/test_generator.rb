require "rails/generators/base"

module InertiaI18n
  module Generators
    class TestGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def create_test_file
        if rspec?
          template "i18n_spec.rb", "spec/inertia_i18n_spec.rb"
        else
          template "i18n_test.rb", "test/inertia_i18n_test.rb"
        end
      end

      private

      def rspec?
        defined?(RSpec) && Dir.exist?("spec")
      end
    end
  end
end
