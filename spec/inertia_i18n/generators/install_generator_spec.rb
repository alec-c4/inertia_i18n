# frozen_string_literal: true

require "spec_helper"
require "generators/inertia_i18n/install_generator"

RSpec.describe InertiaI18n::Generators::InstallGenerator do
  let(:destination) { File.expand_path("../../../tmp/generator_test", __dir__) }

  before do
    FileUtils.mkdir_p(destination)
    Dir.chdir(destination) do
      FileUtils.mkdir_p("config/locales")
      File.write("Gemfile", "")
      File.write("package.json", {dependencies: {react: "18.0.0"}}.to_json)
    end
  end

  after do
    FileUtils.rm_rf(destination)
  end

  it "creates expected files and directories" do
    Dir.chdir(destination) do
      # Mock the 'run' method to avoid actual yarn/npm install during tests
      gen = described_class.new([], {}, {destination_root: destination})
      allow(gen).to receive(:run)

      gen.create_directory_structure
      gen.create_sample_locales
      gen.create_initializer

      expect(Dir.exist?("config/locales/frontend")).to be true
      expect(Dir.exist?("config/locales/backend")).to be true
      expect(Dir.exist?("app/frontend/locales")).to be true
      expect(File.exist?("config/locales/frontend/common.en.yml")).to be true
      expect(File.exist?("config/initializers/inertia_i18n.rb")).to be true

      # Check if initializer contains correct scan_paths for React
      content = File.read("config/initializers/inertia_i18n.rb")
      expect(content).to include("jsx,tsx")
    end
  end
end
