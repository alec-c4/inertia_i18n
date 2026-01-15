# frozen_string_literal: true

require "spec_helper"
require "inertia_i18n/file_converter"

RSpec.describe InertiaI18n::FileConverter do
  let(:frontend_path) { "tmp/spec/locales/frontend" }

  let(:common_path) { "tmp/spec/locales/common" }

  let(:target_path) { "tmp/spec/frontend/locales" }

  before do
    FileUtils.mkdir_p(frontend_path)

    FileUtils.mkdir_p(common_path)

    FileUtils.mkdir_p(target_path)

    InertiaI18n.configure do |config|
      config.source_paths = [frontend_path, common_path]

      config.target_path = target_path

      config.locales = %i[en ru]
    end

    # Create dummy YAML files

    File.write(File.join(frontend_path, "en.yml"), {"en" => {"page" => {"title" => "Hello Frontend"}}}.to_yaml)

    File.write(File.join(common_path, "en.yml"), {"en" => {"common" => {"button" => "Click me"}}}.to_yaml)

    File.write(File.join(frontend_path, "ru.yml"), {"ru" => {"page" => {"title" => "Привет Фронтенд"}}}.to_yaml)
  end

  after do
    FileUtils.rm_rf("tmp/spec")

    InertiaI18n.reset_configuration!
  end

  describe ".convert_all" do
    it "merges keys from multiple source_paths" do
      described_class.convert_all

      en_json_path = File.join(target_path, "en.json")

      expect(File.exist?(en_json_path)).to be true

      en_data = JSON.parse(File.read(en_json_path))

      expect(en_data["page"]["title"]).to eq("Hello Frontend")

      expect(en_data["common"]["button"]).to eq("Click me")
    end
  end

  describe ".convert_locale" do
    it "converts a single locale from all source_paths" do
      described_class.convert_locale(:en)

      en_json_path = File.join(target_path, "en.json")

      ru_json_path = File.join(target_path, "ru.json")

      expect(File.exist?(en_json_path)).to be true

      expect(File.exist?(ru_json_path)).to be false

      en_data = JSON.parse(File.read(en_json_path))

      expect(en_data["page"]["title"]).to eq("Hello Frontend")

      expect(en_data["common"]["button"]).to eq("Click me")
    end
  end
end
