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

      # Apply built-in filters for false positives
      missing = apply_missing_filters(missing)

      # Filter out keys that have i18next plural suffixes (e.g., key_one, key_other)
      missing = filter_plural_keys(missing, available_keys)

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

      # Apply sibling detection for enum-like keys (status, types, etc.)
      if @config.sibling_detection[:enabled]
        sibling_prefixes = detect_sibling_prefixes(used_keys)
        unused = unused.reject do |key|
          sibling_prefixes.any? { |prefix| key.start_with?(prefix) }
        end
      end

      # Filter out i18next plural variant keys when base key is used
      # e.g., if "key" is used, don't mark "key_one", "key_other" as unused
      unused = filter_plural_variant_keys(unused, used_keys)

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

    # Filter out keys that have i18next pluralization suffixes present
    # e.g., if "key_one" or "key_other" exists, consider "key" as present
    def filter_plural_keys(keys, available_keys)
      # i18next plural suffixes
      plural_suffixes = %w[_zero _one _two _few _many _other]

      keys.reject do |key|
        plural_suffixes.any? do |suffix|
          available_keys.include?("#{key}#{suffix}")
        end
      end
    end

    # Filter out i18next plural variant keys when base key is used
    # e.g., if "key" is used in code, don't mark "key_one", "key_other" as unused
    def filter_plural_variant_keys(keys, used_keys)
      plural_suffixes = %w[_zero _one _two _few _many _other]

      keys.reject do |key|
        # Check if this key ends with a plural suffix
        plural_suffixes.any? do |suffix|
          next false unless key.end_with?(suffix)

          # Extract base key and check if it's used
          base_key = key.chomp(suffix)
          used_keys.include?(base_key)
        end
      end
    end

    # Filter out false-positive missing keys based on configured filters
    def apply_missing_filters(keys)
      filters = @config.missing_key_filters
      return keys if filters.nil? || filters.empty?

      keys.reject do |key|
        # Filter by minimum length
        if filters[:min_length] && key.length < filters[:min_length]
          next true
        end

        # Require at least one dot (namespace separator)
        if filters[:require_dot] && !key.include?(".")
          next true
        end

        # Filter out incomplete keys ending with dot (string concatenation patterns)
        if key.end_with?(".")
          next true
        end

        # Apply exclusion patterns
        if filters[:exclude_patterns]
          next true if filters[:exclude_patterns].any? { |p| key.match?(p) }
        end

        false
      end
    end

    # Detect sibling prefixes from used keys for enum-like namespaces
    # If code uses "hr.vacancies.status.open", consider all "hr.vacancies.status.*" as potentially used
    def detect_sibling_prefixes(used_keys)
      prefixes = Set.new
      suffixes = @config.sibling_detection[:suffixes] || []

      used_keys.each do |key|
        parts = key.split(".")
        next if parts.length < 2

        # Check if any suffix matches a part of the key
        suffixes.each do |suffix|
          # Find index of suffix in key parts (handle both singular and plural)
          idx = parts.index(suffix) ||
            parts.index("#{suffix}s") ||
            parts.index(suffix.chomp("s"))

          # If found and there's at least one more segment after it
          if idx && idx < parts.length - 1
            prefix = parts[0..idx].join(".") + "."
            prefixes.add(prefix)
          end
        end
      end

      prefixes.to_a
    end
  end
end
