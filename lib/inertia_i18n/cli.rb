# frozen_string_literal: true

require "thor"
require "json"
require "yaml"

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

    desc "normalize", "Sort and format JSON locale files"
    option :config, type: :string, desc: "Path to config file"
    def normalize
      load_config(options[:config])
      config = InertiaI18n.configuration

      config.locales.each do |locale|
        file = File.join(config.target_path, "#{locale}.json")
        next unless File.exist?(file)

        data = JSON.parse(File.read(file))
        sorted_data = deep_sort(data)
        File.write(file, JSON.pretty_generate(sorted_data) + "\n")

        puts "Normalized #{file}"
      end
    end

    desc "version", "Show version"
    def version
      puts "InertiaI18n #{InertiaI18n::VERSION}"
    end

    desc "init", "Generate configuration file"
    option :path, type: :string, default: "config/initializers/inertia_i18n.rb"
    def init
      template = <<~RUBY
        # frozen_string_literal: true

        InertiaI18n.configure do |config|
          # Source path for Rails YAML locale files
          config.source_path = "config/locales"

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

          # Interpolation conversion (Rails %<var>s -> i18next {{var}})
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

      FileUtils.mkdir_p(File.dirname(options[:path]))
      File.write(options[:path], template)
      puts "Created #{options[:path]}"
    end

    private

    def load_config(config_path)
      return unless config_path && File.exist?(config_path)

      require config_path
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
        end
      end
      puts
    end

    def deep_sort(data)
      case data
      when Hash
        data.keys.sort.each_with_object({}) do |key, sorted|
          sorted[key] = deep_sort(data[key])
        end
      when Array
        data.map { |item| deep_sort(item) }
      else
        data
      end
    end
  end
end
