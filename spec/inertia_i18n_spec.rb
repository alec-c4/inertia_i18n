# frozen_string_literal: true

RSpec.describe InertiaI18n do
  it "has a version number" do
    expect(InertiaI18n::VERSION).not_to be_nil
  end

  it "provides configuration" do
    expect(described_class.configuration).to be_a(InertiaI18n::Configuration)
  end

  it "allows configuration via block" do
    described_class.configure do |config|
      config.locales = %i[en ru]
    end

    expect(described_class.configuration.locales).to eq(%i[en ru])
  ensure
    described_class.reset_configuration!
  end
end
