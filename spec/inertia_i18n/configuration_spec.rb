# frozen_string_literal: true

RSpec.describe InertiaI18n::Configuration do
  let(:config) { described_class.new }

  after { InertiaI18n.reset_configuration! }

  describe "defaults" do
    it "has default source_paths" do
      expect(config.source_paths).to eq(["config/locales/frontend"])
    end

    it "has default target_path" do
      expect(config.target_path).to eq("app/frontend/locales")
    end

    it "has default locales" do
      expect(config.locales).to eq(%i[en])
    end

    it "has default interpolation settings" do
      expect(config.interpolation).to eq({from: "%{", to: "{{"})
    end

    it "has default scan_paths" do
      expect(config.scan_paths).to eq(["app/frontend/**/*.{js,ts,jsx,tsx,svelte,vue}"])
    end

    it "has default translation_functions" do
      expect(config.translation_functions).to eq(%w[t $t i18n.t])
    end
  end

  describe "#primary_locale" do
    it "returns first locale" do
      config = described_class.new
      config.locales = %i[en ru]
      expect(config.primary_locale).to eq(:en)
    end
  end

  describe "#secondary_locales" do
    it "returns all locales except first" do
      config = described_class.new
      config.locales = %i[en ru de]
      expect(config.secondary_locales).to eq(%i[ru de])
    end
  end

  describe "InertiaI18n.configure" do
    it "yields configuration block" do
      InertiaI18n.configure do |config|
        config.source_paths = ["custom/locales"]
      end
      expect(InertiaI18n.configuration.source_paths).to eq(["custom/locales"])
    end
  end

  describe "#load_from_yaml" do
    let(:yaml_dir) { File.expand_path("../../tmp/config", __dir__) }
    let(:yaml_path) { File.join(yaml_dir, "inertia_i18n.yml") }

    before { FileUtils.mkdir_p(yaml_dir) }
    after { FileUtils.rm_rf(yaml_dir) }

    it "loads basic string settings" do
      File.write(yaml_path, <<~YAML)
        target_path: "custom/locales"
        source_pattern: "**/*.yml"
      YAML

      config.load_from_yaml(yaml_path)
      expect(config.target_path).to eq("custom/locales")
      expect(config.source_pattern).to eq("**/*.yml")
    end

    it "loads array settings" do
      File.write(yaml_path, <<~YAML)
        source_paths:
          - config/locales/frontend
          - config/locales/shared
        scan_paths:
          - "app/frontend/**/*.{js,ts}"
      YAML

      config.load_from_yaml(yaml_path)
      expect(config.source_paths).to eq(["config/locales/frontend", "config/locales/shared"])
      expect(config.scan_paths).to eq(["app/frontend/**/*.{js,ts}"])
    end

    it "converts locales to symbols" do
      File.write(yaml_path, <<~YAML)
        locales:
          - en
          - ru
          - de
      YAML

      config.load_from_yaml(yaml_path)
      expect(config.locales).to eq(%i[en ru de])
    end

    it "loads interpolation settings" do
      File.write(yaml_path, <<~YAML)
        interpolation:
          from: "%{"
          to: "{{"
      YAML

      config.load_from_yaml(yaml_path)
      expect(config.interpolation).to eq({from: "%{", to: "{{"})
    end

    it "loads dynamic_patterns as hash" do
      File.write(yaml_path, <<~YAML)
        dynamic_patterns:
          "status.": Dynamic status keys
          "priority.": Dynamic priority keys
      YAML

      config.load_from_yaml(yaml_path)
      expect(config.dynamic_patterns).to eq({"status." => "Dynamic status keys", "priority." => "Dynamic priority keys"})
    end

    it "loads ignore_unused and ignore_missing" do
      File.write(yaml_path, <<~YAML)
        ignore_unused:
          - "legacy.old_key"
          - "deprecated.*"
        ignore_missing:
          - "future.feature"
      YAML

      config.load_from_yaml(yaml_path)
      expect(config.ignore_unused).to eq(["legacy.old_key", "deprecated.*"])
      expect(config.ignore_missing).to eq(["future.feature"])
    end

    it "loads translation_functions" do
      File.write(yaml_path, <<~YAML)
        translation_functions:
          - t
          - $t
          - i18n.t
          - useTranslation
      YAML

      config.load_from_yaml(yaml_path)
      expect(config.translation_functions).to eq(%w[t $t i18n.t useTranslation])
    end

    it "loads key_properties" do
      File.write(yaml_path, <<~YAML)
        key_properties:
          - titleKey
          - labelKey
      YAML

      config.load_from_yaml(yaml_path)
      expect(config.key_properties).to eq(%w[titleKey labelKey])
    end

    it "loads sibling_detection settings" do
      File.write(yaml_path, <<~YAML)
        sibling_detection:
          enabled: false
          suffixes:
            - status
            - types
      YAML

      config.load_from_yaml(yaml_path)
      expect(config.sibling_detection).to eq({enabled: false, suffixes: %w[status types]})
    end

    it "loads missing_key_filters with exclude_patterns as regexps" do
      File.write(yaml_path, <<~YAML)
        missing_key_filters:
          min_length: 3
          require_dot: false
          exclude_patterns:
            - "^[A-Z_]+$"
            - "^/[\\\\w/-]*$"
      YAML

      config.load_from_yaml(yaml_path)
      expect(config.missing_key_filters[:min_length]).to eq(3)
      expect(config.missing_key_filters[:require_dot]).to be(false)
      expect(config.missing_key_filters[:exclude_patterns]).to all(be_a(Regexp))
    end

    it "ignores unknown keys" do
      File.write(yaml_path, <<~YAML)
        unknown_setting: "value"
        target_path: "custom/locales"
      YAML

      expect { config.load_from_yaml(yaml_path) }.not_to raise_error
      expect(config.target_path).to eq("custom/locales")
    end

    it "raises error for non-existent file" do
      expect { config.load_from_yaml("/nonexistent/path.yml") }.to raise_error(Errno::ENOENT)
    end
  end
end
