# frozen_string_literal: true

RSpec.describe InertiaI18n::HealthChecker do
  describe "pluralization" do
    let(:locales_path) { File.expand_path("../fixtures/locales_plurals", __dir__) }
    let(:frontend_path) { File.expand_path("../fixtures/frontend", __dir__) }

    before do
      FileUtils.mkdir_p(locales_path)
      InertiaI18n.configure do |config|
        config.scan_paths = ["#{frontend_path}/**/*.{js,ts,svelte,jsx,tsx,vue}"]
        config.target_path = locales_path
        config.locales = %i[en ru]
      end
    end

    after do
      FileUtils.rm_rf(locales_path)
      InertiaI18n.reset_configuration!
    end

    it "groups plural keys in unused check" do
      File.write(
        File.join(locales_path, "en.json"),
        JSON.pretty_generate({
          "apples_one" => "apple",
          "apples_other" => "apples"
        })
      )
      # ru.json matches
      File.write(
        File.join(locales_path, "ru.json"),
        JSON.pretty_generate({
          "apples_one" => "яблоко",
          "apples_few" => "яблока",
          "apples_many" => "яблок",
          "apples_other" => "яблок"
        })
      )

      checker = described_class.new.check!(checks: [:unused])
      unused_keys = checker.issues[:unused].map { |i| i[:key] }

      expect(unused_keys).to include("apples (plural forms)")
      expect(unused_keys).not_to include("apples_one")
      expect(unused_keys).not_to include("apples_other")
    end

    it "groups plural keys in unsync check and avoids false positives for different forms" do
      # English has one/other, Russian has one/few/many/other
      File.write(
        File.join(locales_path, "en.json"),
        JSON.pretty_generate({
          "apples_one" => "apple",
          "apples_other" => "apples"
        })
      )
      File.write(
        File.join(locales_path, "ru.json"),
        JSON.pretty_generate({
          "apples_one" => "яблоко",
          "apples_few" => "яблока",
          "apples_many" => "яблок",
          "apples_other" => "яблок"
        })
      )

      checker = described_class.new.check!(checks: [:unsync])
      expect(checker.issues[:unsync]).to be_empty
    end

    it "detects when a plural key is entirely missing in one locale" do
      File.write(
        File.join(locales_path, "en.json"),
        JSON.pretty_generate({
          "apples_one" => "apple",
          "apples_other" => "apples"
        })
      )
      File.write(
        File.join(locales_path, "ru.json"),
        JSON.pretty_generate({
          "some_other_key" => "value"
        })
      )

      checker = described_class.new.check!(checks: [:unsync])
      unsync_keys = checker.issues[:unsync].map { |i| i[:key] }

      expect(unsync_keys).to include("apples (plural forms)")
    end

    it "does not mark base key as missing if plural forms exist" do
      # Simulate code using t('apples')
      File.write(
        File.join(locales_path, "en.json"),
        JSON.pretty_generate({
          "apples_one" => "apple",
          "apples_other" => "apples"
        })
      )

      # We need a file that uses 'apples'
      test_src = File.join(locales_path, "test.js")
      File.write(test_src, "t('apples')")

      InertiaI18n.configure do |config|
        config.scan_paths = [test_src]
        config.target_path = locales_path
      end

      checker = described_class.new.check!(checks: [:missing])
      missing_keys = checker.issues[:missing].map { |i| i[:key] }

      expect(missing_keys).not_to include("apples")
    end
  end
end
