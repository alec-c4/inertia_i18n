# frozen_string_literal: true

require "thor"
require "json"
require "yaml"
require "listen"

module InertiaI18n
  class Cli < Thor
    def self.exit_on_failure?
      true
    end

    desc "convert", "Convert YAML locales to JSON"
    option :locale, type: :string, desc: "Specific locale to convert"
    option :config, type: :string, desc: "Path to config file"
    def convert
      load_config(options[:config])

      if options[:locale]
        result = FileConverter.convert_locale(options[:locale].to_sym)
        print_convert_result(result)
      else
        results = FileConverter.convert_all
        results.each { |r| print_convert_result(r) }
      end
    end

    desc "watch", "Watch YAML locales for changes and auto-convert"
    option :config, type: :string, desc: "Path to config file"
    def watch
      load_config(options[:config])
      config = InertiaI18n.configuration
      paths = config.source_paths.map(&:to_s)

      puts "👀 Watching #{paths.join(", ")} for YAML changes..."

      listener = Listen.to(*paths, only: /\.(yml|yaml)$/) do |modified, added, removed|
        puts "📝 Detected locale file changes..."
        (modified + added + removed).each do |file|
          puts "   #{file}"
        end

        puts "🔄 Regenerating JSON files..."
        results = FileConverter.convert_all
        results.each { |r| print_convert_result(r) }
        puts "✅ Done!"
      end

      listener.start
      sleep
    rescue Interrupt
      puts "\n👋 Stopping watch mode..."
      listener.stop
    end

    desc "scan", "Scan frontend code for translation key usage"
    option :format, type: :string, default: "text", enum: %w[text json yaml]
    option :config, type: :string, desc: "Path to config file"
    def scan
      load_config(options[:config])

      scanner = Scanner.new
      results = scanner.scan

      case options[:format]
      when "json"
        puts JSON.pretty_generate(results.to_h)
      when "yaml"
        puts results.to_h.to_yaml
      else
        print_scan_results(results)
      end
    end

    desc "missing", "Find missing translation keys"
    option :format, type: :string, default: "text", enum: %w[text json]
    option :verbose, type: :boolean, default: false, aliases: "-v"
    option :config, type: :string, desc: "Path to config file"
    def missing
      load_config(options[:config])

      checker = HealthChecker.new.check!(checks: [:missing])

      if options[:format] == "json"
        puts JSON.pretty_generate({issues: checker.issues[:missing], count: checker.issues[:missing].size})
      else
        print_issues("Missing Keys (used in code, not translated)", checker.issues[:missing], options[:verbose])
        puts "#{checker.issues[:missing].size} missing key(s) found." if checker.issues[:missing].any?
        puts "No missing keys found." if checker.issues[:missing].empty?
      end

      exit 1 if checker.issues[:missing].any?
    end

    desc "unused", "Find unused translation keys"
    option :format, type: :string, default: "text", enum: %w[text json]
    option :verbose, type: :boolean, default: false, aliases: "-v"
    option :config, type: :string, desc: "Path to config file"
    def unused
      load_config(options[:config])

      checker = HealthChecker.new.check!(checks: [:unused])

      if options[:format] == "json"
        puts JSON.pretty_generate({issues: checker.issues[:unused], count: checker.issues[:unused].size})
      else
        print_issues("Unused Keys (translated, not used in code)", checker.issues[:unused], options[:verbose])
        puts "#{checker.issues[:unused].size} unused key(s) found." if checker.issues[:unused].any?
        puts "No unused keys found." if checker.issues[:unused].empty?
      end

      exit 1 if checker.issues[:unused].any?
    end

    desc "health", "Check translation health (missing, unused, unsync)"
    option :format, type: :string, default: "text", enum: %w[text json]
    option :verbose, type: :boolean, default: false, aliases: "-v"
    option :config, type: :string, desc: "Path to config file"
    def health
      load_config(options[:config])

      checker = HealthChecker.new.check!

      if options[:format] == "json"
        output = {
          healthy: checker.healthy?,
          summary: checker.summary,
          issues: checker.issues
        }
        puts JSON.pretty_generate(output)
      else
        print_health_results(checker, options[:verbose])
      end

      exit 1 unless checker.healthy?
    end

    desc "normalize", "Sort and format YAML and JSON locale files"
    option :config, type: :string, desc: "Path to config file"
    def normalize
      load_config(options[:config])

      Normalizer.new.normalize
    end

    desc "version", "Show version"
    def version
      puts "InertiaI18n #{InertiaI18n::VERSION}"
    end

    desc "init", "Generate configuration file"
    option :format, type: :string, default: "ruby", enum: %w[ruby yaml], desc: "Config format (ruby or yaml)"
    option :path, type: :string, desc: "Output path (auto-detected from format if not specified)"
    def init
      format = options[:format]
      path = options[:path] || default_init_path(format)

      content = (format == "yaml") ? yaml_config_template : ruby_config_template

      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)
      puts "Created #{path}"
    end

    private

    def default_init_path(format)
      if format == "yaml"
        "config/inertia_i18n.yml"
      else
        "config/initializers/inertia_i18n.rb"
      end
    end

    def ruby_config_template
      <<~RUBY
        # frozen_string_literal: true

        InertiaI18n.configure do |config|
          # Source path for Rails YAML locale files
          config.source_paths = ["config/locales/frontend"]

          # Target path for generated i18next JSON files
          config.target_path = "app/frontend/locales"

          # Locales to process (first is primary)
          config.locales = %i[en]

          # YAML file pattern to match
          config.source_pattern = "**/*.{yml,yaml}"

          # Paths to scan for translation usage
          config.scan_paths = ["app/frontend/**/*.{js,ts,jsx,tsx,svelte,vue}"]

          # Translation function names to detect
          config.translation_functions = %w[t $t i18n.t]

          # Interpolation conversion (Rails %{var} -> i18next {{var}})
          config.interpolation = { from: "%{", to: "{{" }

          # Dynamic key patterns (prefix => description)
          # Keys matching these prefixes won't be marked as unused
          config.dynamic_patterns = {
            # "status." => "Dynamic status keys"
          }

          # Keys to ignore during unused check
          config.ignore_unused = []

          # Keys to ignore during missing check
          config.ignore_missing = []
        end
      RUBY
    end

    def yaml_config_template
      <<~YAML
        # InertiaI18n configuration
        # See: https://github.com/alec-c4/inertia_i18n

        # Source paths for Rails YAML locale files
        source_paths:
          - config/locales/frontend

        # Target path for generated i18next JSON files
        target_path: app/frontend/locales

        # Locales to process (first is primary)
        locales:
          - en

        # YAML file pattern to match
        source_pattern: "**/*.{yml,yaml}"

        # Interpolation conversion (Rails %{var} -> i18next {{var}})
        interpolation:
          from: "%{"
          to: "{{"

        # Paths to scan for translation usage
        scan_paths:
          - "app/frontend/**/*.{js,ts,jsx,tsx,svelte,vue}"

        # Translation function names to detect
        translation_functions:
          - t
          - $t
          - i18n.t

        # Dynamic key patterns (prefix => description)
        # Keys matching these prefixes won't be marked as unused
        # dynamic_patterns:
        #   "status.": Dynamic status keys

        # Keys to ignore during unused check
        ignore_unused: []

        # Keys to ignore during missing check
        ignore_missing: []

        # Object properties that contain translation keys
        key_properties:
          - titleKey
          - labelKey
          - messageKey
          - descriptionKey
          - placeholderKey
          - key

        # Sibling detection for enum-like keys
        sibling_detection:
          enabled: true
          suffixes:
            - status
            - statuses
            - types
            - type
            - priorities
            - priority

        # Filters for false-positive missing keys
        missing_key_filters:
          min_length: 4
          require_dot: true
          exclude_patterns:
            - "^/[\\\\w/-]*$"
            - "^[A-Z_]+$"
            - "^\\\\w+_id$"
            - "^[a-z]{2}(-[A-Z]{2})?$"
      YAML
    end

    def load_config(config_path)
      if config_path && File.exist?(config_path)
        if config_path.end_with?(".yml", ".yaml")
          InertiaI18n.configuration.load_from_yaml(config_path)
        else
          require config_path
        end
        return
      end

      # Auto-detect YML config
      yaml_path = "config/inertia_i18n.yml"
      InertiaI18n.configuration.load_from_yaml(yaml_path) if File.exist?(yaml_path)
    end

    def print_convert_result(result)
      puts "Generated #{result[:output_file]}"
      puts "  Locale: #{result[:locale]}"
      puts "  Keys: #{result[:keys_count]}"
      puts "  Source files: #{result[:source_files]}"
      puts
    end

    def print_scan_results(results)
      puts
      puts "Scanning frontend code for translation usage..."
      puts
      puts "Statistics:"
      puts "  Files scanned: #{results.files.count}"
      puts "  Static keys found: #{results.static_keys.count}"
      puts "  Dynamic patterns: #{results.dynamic_patterns.count}"

      if results.dynamic_patterns.any?
        puts
        puts "Dynamic patterns detected (manual review needed):"
        results.dynamic_patterns.each do |pattern|
          puts "  - #{pattern[:pattern]}*"
        end
      end
      puts
    end

    def print_health_results(checker, verbose)
      puts
      puts "Running translation health check..."
      puts

      print_issues("Missing Keys (used in code, not translated)", checker.issues[:missing], verbose)
      print_issues("Unused Keys (translated, not used in code)", checker.issues[:unused], verbose)
      print_issues("Locale Synchronization Issues", checker.issues[:unsync], verbose)

      summary = checker.summary

      if checker.healthy?
        puts "All checks passed! Translations are healthy."
      else
        puts "Health check failed!"
        puts "  Errors: #{summary[:total_errors]}"
        puts "  Warnings: #{summary[:total_warnings]}"
      end
      puts
    end

    def print_issues(title, issues, verbose)
      return if issues.empty?

      icon = (issues.first[:severity] == :error) ? "ERROR" : "WARNING"
      puts "[#{icon}] #{title}: #{issues.count}"

      if verbose
        issues.each do |issue|
          puts "  - #{issue[:key]}"
          if issue[:occurrences]&.any?
            issue[:occurrences].each do |loc|
              puts "    ↳ #{loc[:file]}:#{loc[:line]}"
            end
          end
        end
      else
        # In non-verbose mode, show first occurrence for context
        issues.take(5).each do |issue|
          loc = issue[:occurrences]&.first
          loc_str = loc ? " (#{loc[:file]}:#{loc[:line]})" : ""
          puts "  - #{issue[:key]}#{loc_str}"
        end
        puts "  ... and #{issues.count - 5} more (use --verbose to see all)" if issues.count > 5
      end
      puts
    end
  end
end
