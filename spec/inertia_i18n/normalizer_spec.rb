# frozen_string_literal: true

require "spec_helper"
require "inertia_i18n/normalizer"

RSpec.describe InertiaI18n::Normalizer do
  let(:source_path) { "tmp/spec/locales" }
  let(:target_path) { "tmp/spec/frontend/locales" }

  before do
    FileUtils.mkdir_p(source_path)
    FileUtils.mkdir_p(target_path)

    InertiaI18n.configure do |config|
      config.source_paths = [source_path]
      config.target_path = target_path
      config.locales = %i[en]
    end
  end

  after do
    FileUtils.rm_rf("tmp/spec")
    InertiaI18n.reset_configuration!
  end

  describe "#normalize" do
    it "sorts keys in YAML files" do
      # Create an unsorted YAML file
      unsorted_data = {
        "en" => {
          "b_key" => "value",
          "a_key" => "value",
          "nested" => {
            "z_key" => "value",
            "y_key" => "value"
          }
        }
      }
      yaml_file = File.join(source_path, "en.yml")
      File.write(yaml_file, unsorted_data.to_yaml)

      described_class.new.normalize

      content = File.read(yaml_file)

      # Check if a_key comes before b_key
      expect(content.index("a_key")).to be < content.index("b_key")

      # Check if y_key comes before z_key
      expect(content.index("y_key")).to be < content.index("z_key")
    end

    it "sorts keys in JSON files" do
      # Create an unsorted JSON file
      unsorted_data = {
        "b_key" => "value",
        "a_key" => "value",
        "nested" => {
          "z_key" => "value",
          "y_key" => "value"
        }
      }
      json_file = File.join(target_path, "en.json")
      File.write(json_file, JSON.dump(unsorted_data))

      described_class.new.normalize

      content = File.read(json_file)

      # Check if a_key comes before b_key
      expect(content.index("a_key")).to be < content.index("b_key")

      # Check if y_key comes before z_key
      expect(content.index("y_key")).to be < content.index("z_key")
    end

    it "handles array of hashes correctly" do
      unsorted_data = {
        "en" => {
          "list" => [
            {"z" => 1, "a" => 2},
            {"d" => 3, "c" => 4}
          ]
        }
      }
      yaml_file = File.join(source_path, "en.yml")
      File.write(yaml_file, unsorted_data.to_yaml)

      described_class.new.normalize

      content = File.read(yaml_file)

      # Inside first item, a comes before z
      expect(content.index("a")).to be < content.index("z")

      # Inside second item, c comes before d
      expect(content.index("c")).to be < content.index("d")
    end
  end
end
