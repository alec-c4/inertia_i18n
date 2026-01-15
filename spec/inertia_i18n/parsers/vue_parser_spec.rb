# frozen_string_literal: true

require "spec_helper"
require "inertia_i18n/parsers/vue_parser"

RSpec.describe InertiaI18n::Parsers::VueParser do
  let(:parser) { described_class.new }
  let(:fixture_file) { "spec/fixtures/frontend/components/UserProfile.vue" }

  it "extracts keys from .vue file" do
    result = parser.extract_keys(fixture_file)

    expect(result[:static]).to include(
      "vue.profile_title",
      "vue.greeting",
      "vue.script_key"
    )
    expect(result[:dynamic].first).to include(pattern: "vue.dynamic.")
  end
end
