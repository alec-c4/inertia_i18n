require "test_helper"
require "inertia_i18n/health_checker"
require "inertia_i18n/file_converter"

class I18nTest < ActiveSupport::TestCase
  test "translations are healthy" do
    # Ensure JSON files are up-to-date before checking
    InertiaI18n::FileConverter.convert_all

    checker = InertiaI18n::HealthChecker.new.check!

    message = ["\nTranslation health check failed!"]

    if checker.issues[:missing].any?
      message << "\nMissing Keys (#{checker.issues[:missing].count}):"
      checker.issues[:missing].each { |i| message << "  - #{i[:key]}" }
    end

    if checker.issues[:unused].any?
      message << "\nUnused Keys (#{checker.issues[:unused].count}):"
      checker.issues[:unused].each { |i| message << "  - #{i[:key]}" }
    end

    if checker.issues[:unsync].any?
      message << "\nLocale Synchronization Issues (#{checker.issues[:unsync].count}):"
      checker.issues[:unsync].each { |i| message << "  - #{i[:key]} (in #{i[:locale]})" }
    end

    assert checker.healthy?, message.join("\n")
  end
end
