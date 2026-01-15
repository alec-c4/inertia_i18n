# frozen_string_literal: true

require "spec_helper"
require "inertia_i18n/parsers/javascript_parser"

RSpec.describe InertiaI18n::Parsers::JavaScriptParser do
  let(:parser) { described_class.new }
  let(:js_file) { "spec/fixtures/frontend/utils/helpers.js" }
  let(:ts_file) { "spec/fixtures/frontend/utils/helpers.ts" }

  it "extracts keys from .js file" do
    result = parser.extract_keys(js_file)

    expect(result[:static]).to include("javascript.message")
    expect(result[:dynamic].first).to include(pattern: "javascript.dynamic.")
  end

  it "handles different quote types (single, double, backticks)" do
    content = <<~JS
      t('single.quotes');
      t("double.quotes");
      t(`backtick.static`);
      t(`backtick.dynamic.${var}`);
    JS
    result = parser.extract_keys_from_content(content)

    expect(result[:static]).to include("single.quotes", "double.quotes", "backtick.static")
    expect(result[:dynamic].first).to include(pattern: "backtick.dynamic.")
  end

  it "extracts keys from .ts file" do
    result = parser.extract_keys(ts_file)

    expect(result[:static]).to include("typescript.message")
    expect(result[:dynamic].first).to include(pattern: "typescript.dynamic.")
  end
end
