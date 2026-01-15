# frozen_string_literal: true

require "spec_helper"
require "inertia_i18n/parsers/svelte_parser"

RSpec.describe InertiaI18n::Parsers::SvelteParser do
  let(:parser) { described_class.new }
  let(:fixture_file) { "spec/fixtures/frontend/pages/Home.svelte" }

  it "extracts keys from .svelte file" do
    result = parser.extract_keys(fixture_file)

    expect(result[:static]).to include("common.hello", "common.goodbye")
    expect(result[:dynamic].first).to include(pattern: "status.")
  end
end
