require "rails/generators"
require "json"

module InertiaI18n
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Installs InertiaI18n, creates directory structure, and adds frontend dependencies."

      def check_dependencies
        @framework = detect_framework
      end

      def create_directory_structure
        say "Creating locale directory structure...", :green
        empty_directory "config/locales/frontend"
        empty_directory "config/locales/backend"
        empty_directory "app/frontend/locales"
      end

      def move_existing_locales
        # Move standard Rails locales to backend if they exist in the root
        %w[en.yml ru.yml].each do |file|
          source = "config/locales/#{file}"
          if File.exist?(source)
            say "Moving #{file} to config/locales/backend/", :yellow
            rename_file source, "config/locales/backend/#{file}"
          end
        end
      end

      def create_sample_locales
        copy_file "common.en.yml", "config/locales/frontend/common.en.yml"
      end

      def create_initializer
        template "inertia_i18n.rb.tt", "config/initializers/inertia_i18n.rb"
      end

      def add_frontend_dependencies
        packages_to_add = ["i18next"]

        case @framework
        when :react
          say "Detected React. Adding react-i18next...", :green
          packages_to_add << "react-i18next"
        when :vue
          say "Detected Vue. Adding i18next-vue...", :green
          packages_to_add << "i18next-vue"
        when :svelte
          say "Detected Svelte.", :green
        end

        return unless File.exist?("package.json")

        # Detect package manager
        cmd = if File.exist?("yarn.lock")
          "yarn add"
        elsif File.exist?("bun.lockb")
          "bun add"
        else
          "npm install"
        end

        run "#{cmd} #{packages_to_add.join(" ")}"
      end

      def show_post_install_info
        say "\n✅ InertiaI18n installed successfully!", :green
        say "\nNext steps:", :bold
        say "1. Import and initialize i18next in your frontend application (e.g., app/frontend/i18n.js)."
        say "2. Use the generated locales in config/locales/frontend/."
        say "3. Run `bundle exec inertia_i18n convert` to generate the initial JSON files."
        say "4. Start your server and happy translating!\n\n"
      end

      private

      def detect_framework
        return unless File.exist?("package.json")

        package_json = JSON.parse(File.read("package.json"))
        dependencies = package_json["dependencies"] || {}
        dev_dependencies = package_json["devDependencies"] || {}
        all_deps = dependencies.merge(dev_dependencies)

        if all_deps.key?("react")
          :react
        elsif all_deps.key?("vue")
          :vue
        elsif all_deps.key?("svelte")
          :svelte
        end
      end

      def rename_file(old_name, new_name)
        FileUtils.mv(old_name, new_name)
      end
    end
  end
end
