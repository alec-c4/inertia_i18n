# frozen_string_literal: true

require "spec_helper"
require "generators/inertia_i18n/test_generator"

RSpec.describe InertiaI18n::Generators::TestGenerator do
  let(:destination) { File.expand_path("../../../tmp/generator_test", __dir__) }

  before do
    FileUtils.mkdir_p(destination)
  end

  after do
    FileUtils.rm_rf(destination)
  end

  it "creates rspec file when spec directory exists" do
    Dir.chdir(destination) do
      FileUtils.mkdir_p("spec")

      gen = described_class.new([], {}, {destination_root: destination})
      gen.create_test_file

      expect(File.exist?("spec/inertia_i18n_health_spec.rb")).to be true
      content = File.read("spec/inertia_i18n_health_spec.rb")
      expect(content).to include("rails_helper")
    end
  end

  it "creates minitest file when spec directory does not exist" do
    Dir.chdir(destination) do
      FileUtils.mkdir_p("test")

      gen = described_class.new([], {}, {destination_root: destination})
      gen.create_test_file

      expect(File.exist?("test/inertia_i18n_health_test.rb")).to be true
      content = File.read("test/inertia_i18n_health_test.rb")
      expect(content).to include("test_helper")
    end
  end
end
