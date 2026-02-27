# frozen_string_literal: true

require "spec_helper"
require "inertia_i18n/scanner"

RSpec.describe InertiaI18n::Scanner do
  let(:fixtures_path) { File.expand_path("../fixtures/frontend", __dir__) }

  before do
    InertiaI18n.configure do |config|
      config.scan_paths = ["#{fixtures_path}/**/*.{js,ts,svelte,jsx,tsx,vue}"]
    end
  end

  after { InertiaI18n.reset_configuration! }

  describe "#scan" do
    subject(:results) { described_class.new.scan }

    it "returns a ScanResults object" do
      expect(results).to be_a(InertiaI18n::ScanResults)
    end

    it "finds all static keys from all file types" do
      expected_static_keys = %w[
        common.hello
        common.goodbye
        svelte.profile_title
        svelte.greeting
        javascript.message
        typescript.message
        react.profile_title
        react.greeting
        vue.profile_title
        vue.greeting
        vue.script_key
      ]
      expect(results.static_keys).to include(*expected_static_keys)
    end

    it "finds all dynamic patterns from all file types" do
      dynamic_patterns = results.dynamic_patterns.map { |p| p[:pattern] }
      expected_patterns = %w[
        status.
        svelte.dynamic.
        javascript.dynamic.
        typescript.dynamic.
        react.dynamic.
        vue.dynamic.
      ]
      expect(dynamic_patterns).to include(*expected_patterns)
    end

    it "scans the correct number of files" do
      # 6 original + Home.jsx + Home.vue
      expect(results.files.keys.count).to eq(8)
    end

    context "when dynamic_keys is configured" do
      before do
        InertiaI18n.configure do |config|
          config.dynamic_keys = {
            "status." => %w[active inactive]
          }
        end
      end

      it "expands dynamic patterns into static keys" do
        expect(results.static_keys).to include("status.active", "status.inactive")
      end

      it "adds occurrences with file and line number for expanded keys" do
        occurrences = results.occurrences["status.active"]
        expect(occurrences).to be_an(Array)
        expect(occurrences).not_to be_empty
        expect(occurrences.first[:file]).to be_a(String)
        expect(occurrences.first[:line]).to be_a(Integer)
      end
    end
  end
end
