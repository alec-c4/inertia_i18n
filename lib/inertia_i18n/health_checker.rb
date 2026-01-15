# frozen_string_literal: true

module InertiaI18n
  class HealthChecker
    attr_reader :locales, :scan_results, :issues

    def initialize
      @config = InertiaI18n.configuration
      @locales = LocaleLoader.load_all
      @scan_results = Scanner.new.scan
      @issues = {missing: [], unused: [], unsync: []}
    end

    def check!
      check_missing_keys
      check_unused_keys
      check_locale_sync
      self
    end

    def healthy?
      @issues.values.all?(&:empty?)
    end

    def summary
      {
        total_errors: @issues.values.flatten.count { |i| i[:severity] == :error },
        total_warnings: @issues.values.flatten.count { |i| i[:severity] == :warning },
        missing_count: @issues[:missing].size,
        unused_count: @issues[:unused].size,
        unsync_count: @issues[:unsync].size,
        healthy: healthy?
      }
    end

    private

    def check_missing_keys
      primary_locale = @config.primary_locale
      available_keys = Set.new(LocaleLoader.extract_keys(@locales[primary_locale] || {}))
      used_keys = @scan_results.static_keys

      missing = used_keys - available_keys

      # Filter out keys covered by ignore_missing config
      missing = filter_ignored_keys(missing, @config.ignore_missing)

      missing.each do |key|
        @issues[:missing] << {
          key: key,
          severity: :error,
          message: "Key '#{key}' is used in code but missing from #{primary_locale}.json"
        }
      end
    end

    def check_unused_keys
      primary_locale = @config.primary_locale
      available_keys = Set.new(LocaleLoader.extract_keys(@locales[primary_locale] || {}))
      used_keys = @scan_results.static_keys

      # Get dynamic pattern prefixes
      dynamic_prefixes = @scan_results.dynamic_patterns.map { |p| p[:pattern] }

      # Add configured dynamic patterns
      dynamic_prefixes.concat(@config.dynamic_patterns.keys)

      unused = available_keys - used_keys

      # Filter out keys that match dynamic patterns
      unused = unused.reject do |key|
        dynamic_prefixes.any? { |prefix| key.start_with?(prefix) }
      end

      # Filter out keys covered by ignore_unused config
      unused = filter_ignored_keys(unused, @config.ignore_unused)

      unused.each do |key|
        @issues[:unused] << {
          key: key,
          severity: :warning,
          message: "Key '#{key}' exists in #{primary_locale}.json but is not used in code"
        }
      end
    end

    def check_locale_sync
      primary_locale = @config.primary_locale
      primary_keys = Set.new(LocaleLoader.extract_keys(@locales[primary_locale] || {}))

      @config.secondary_locales.each do |locale|
        locale_data = @locales[locale] || {}
        locale_keys = Set.new(LocaleLoader.extract_keys(locale_data))

        missing_in_locale = primary_keys - locale_keys
        extra_in_locale = locale_keys - primary_keys

        missing_in_locale.each do |key|
          @issues[:unsync] << {
            key: key,
            locale: locale,
            severity: :error,
            message: "Key '#{key}' exists in #{primary_locale}.json but missing from #{locale}.json"
          }
        end

        extra_in_locale.each do |key|
          @issues[:unsync] << {
            key: key,
            locale: locale,
            severity: :warning,
            message: "Key '#{key}' exists in #{locale}.json but missing from #{primary_locale}.json"
          }
        end
      end
    end

    def filter_ignored_keys(keys, ignore_patterns)
      return keys if ignore_patterns.empty?

      keys.reject do |key|
        ignore_patterns.any? do |pattern|
          if pattern.is_a?(Regexp)
            key.match?(pattern)
          else
            key == pattern || key.start_with?("#{pattern}.")
          end
        end
      end
    end
  end
end
