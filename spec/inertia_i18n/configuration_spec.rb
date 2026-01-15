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
end
