# frozen_string_literal: true

require "spec_helper"
require "inertia_i18n/parsers/react_parser"

RSpec.describe InertiaI18n::Parsers::ReactParser do
  let(:parser) { described_class.new }
  let(:fixture_file) { "spec/fixtures/frontend/components/UserProfile.jsx" }

  it "extracts keys from .jsx file" do
    result = parser.extract_keys(fixture_file)

    expect(result[:static]).to include("react.profile_title", "react.greeting")
    expect(result[:dynamic].first).to include(pattern: "react.dynamic.")
  end
end
