# frozen_string_literal: true

require "spec_helper"
require "inertia_i18n/parsers/javascript_parser"

RSpec.describe InertiaI18n::Parsers::JavaScriptParser do
  let(:parser) { described_class.new }
  let(:js_file) { "spec/fixtures/frontend/utils/helpers.js" }
  let(:ts_file) { "spec/fixtures/frontend/utils/helpers.ts" }

  it "extracts keys from .js file" do
    result = parser.extract_keys(js_file)
    keys = result[:static].map { |k| k[:key] }

    expect(keys).to include("javascript.message")
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
    keys = result[:static].map { |k| k[:key] }

    expect(keys).to include("single.quotes", "double.quotes", "backtick.static")
    expect(result[:dynamic].first).to include(pattern: "backtick.dynamic.")
  end

  it "extracts keys from magic comments" do
    content = <<~JS
      // inertia-i18n-use magic.comment.single
      /* inertia-i18n-use magic.comment.block */
      /*
        inertia-i18n-use magic.comment.multiline
      */
      // i18n-tasks-use magic.comment.tasks
    JS
    result = parser.extract_keys_from_content(content)
    keys = result[:static].map { |k| k[:key] }

    expect(keys).to include(
      "magic.comment.single",
      "magic.comment.block",
      "magic.comment.multiline",
      "magic.comment.tasks"
    )
  end

  it "extracts keys from .ts file" do
    result = parser.extract_keys(ts_file)
    keys = result[:static].map { |k| k[:key] }

    expect(keys).to include("typescript.message")
    expect(result[:dynamic].first).to include(pattern: "typescript.dynamic.")
  end
end
