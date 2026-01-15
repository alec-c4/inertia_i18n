# frozen_string_literal: true

RSpec.describe InertiaI18n::Converter do
  after { InertiaI18n.reset_configuration! }

  describe "#convert" do
    subject(:converter) { described_class.new(yaml_data, locale: :en) }

    context "with simple key-value pairs" do
      let(:yaml_data) { {"en" => {"greeting" => "Hello"}} }

      it "converts to JSON structure without locale root" do
        expect(converter.convert).to eq({"greeting" => "Hello"})
      end
    end

    context "with nested keys" do
      let(:yaml_data) do
        {"en" => {"user" => {"name" => "Name", "email" => "Email"}}}
      end

      it "preserves nested structure" do
        expect(converter.convert).to eq({
          "user" => {"name" => "Name", "email" => "Email"}
        })
      end
    end

    context "with deeply nested keys" do
      let(:yaml_data) do
        {"en" => {"a" => {"b" => {"c" => {"d" => "deep"}}}}}
      end

      it "preserves deep nesting" do
        expect(converter.convert).to eq({
          "a" => {"b" => {"c" => {"d" => "deep"}}}
        })
      end
    end

    context "with Rails interpolation" do
      let(:yaml_data) { {"en" => {"greeting" => "Hello, %{name}!"}} }

      it "converts to i18next interpolation {{var}}" do
        expect(converter.convert).to eq({"greeting" => "Hello, {{name}}!"})
      end
    end

    context "with multiple interpolations" do
      let(:yaml_data) do
        {"en" => {"message" => "Hello %{first}, meet %{second}!"}}
      end

      it "converts all interpolations" do
        expect(converter.convert).to eq({
          "message" => "Hello {{first}}, meet {{second}}!"
        })
      end
    end

    context "with interpolation in nested keys" do
      let(:yaml_data) do
        {"en" => {"user" => {"welcome" => "Welcome, %{name}!"}}}
      end

      it "converts interpolation in nested values" do
        expect(converter.convert).to eq({
          "user" => {"welcome" => "Welcome, {{name}}!"}
        })
      end
    end

    context "with i18next pluralization (one/other)" do
      let(:yaml_data) do
        {"en" => {"items" => {"one" => "1 item", "other" => "%{count} items"}}}
      end

      it "converts to i18next plural format with _suffix" do
        result = converter.convert
        expect(result).to eq({
          "items_one" => "1 item",
          "items_other" => "{{count}} items"
        })
      end
    end

    context "with Russian pluralization (one/few/many/other)" do
      let(:yaml_data) do
        {
          "ru" => {
            "items" => {
              "one" => "%{count} элемент",
              "few" => "%{count} элемента",
              "many" => "%{count} элементов",
              "other" => "%{count} элементов"
            }
          }
        }
      end

      it "converts all plural forms" do
        converter = described_class.new(yaml_data, locale: :ru)
        result = converter.convert

        expect(result).to eq({
          "items_one" => "{{count}} элемент",
          "items_few" => "{{count}} элемента",
          "items_many" => "{{count}} элементов",
          "items_other" => "{{count}} элементов"
        })
      end
    end

    context "with zero plural form" do
      let(:yaml_data) do
        {"en" => {"items" => {"zero" => "No items", "one" => "1 item", "other" => "%{count} items"}}}
      end

      it "includes zero form" do
        result = converter.convert
        expect(result).to include("items_zero" => "No items")
      end
    end

    context "with arrays" do
      let(:yaml_data) { {"en" => {"months" => %w[Jan Feb Mar]}} }

      it "preserves arrays" do
        expect(converter.convert).to eq({"months" => %w[Jan Feb Mar]})
      end
    end

    context "with arrays containing interpolation" do
      let(:yaml_data) do
        {"en" => {"messages" => ["Hello %{name}", "Goodbye %{name}"]}}
      end

      it "converts interpolation in array items" do
        expect(converter.convert).to eq({
          "messages" => ["Hello {{name}}", "Goodbye {{name}}"]
        })
      end
    end

    context "with numeric values" do
      let(:yaml_data) { {"en" => {"count" => 42, "price" => 19.99}} }

      it "preserves numeric values" do
        expect(converter.convert).to eq({"count" => 42, "price" => 19.99})
      end
    end

    context "with boolean values" do
      let(:yaml_data) { {"en" => {"enabled" => true, "disabled" => false}} }

      it "preserves boolean values" do
        expect(converter.convert).to eq({"enabled" => true, "disabled" => false})
      end
    end

    context "with nil values" do
      let(:yaml_data) { {"en" => {"empty" => nil}} }

      it "preserves nil values" do
        expect(converter.convert).to eq({"empty" => nil})
      end
    end

    context "with mixed nested and plural keys" do
      let(:yaml_data) do
        {
          "en" => {
            "notifications" => {
              "title" => "Notifications",
              "count" => {
                "one" => "1 notification",
                "other" => "%{count} notifications"
              }
            }
          }
        }
      end

      it "handles both nested and plural correctly" do
        result = converter.convert
        expect(result).to eq({
          "notifications" => {
            "title" => "Notifications",
            "count_one" => "1 notification",
            "count_other" => "{{count}} notifications"
          }
        })
      end
    end

    context "with missing locale key" do
      let(:yaml_data) { {"ru" => {"hello" => "Привет"}} }

      it "returns empty hash for missing locale" do
        converter = described_class.new(yaml_data, locale: :en)
        expect(converter.convert).to eq({})
      end
    end

    context "with string locale key" do
      let(:yaml_data) { {"en" => {"hello" => "Hello"}} }

      it "handles string locale parameter" do
        converter = described_class.new(yaml_data, locale: "en")
        expect(converter.convert).to eq({"hello" => "Hello"})
      end
    end
  end

  describe "custom interpolation settings" do
    before do
      InertiaI18n.configure do |config|
        config.interpolation = {from: "%{", to: "${"}
      end
    end

    it "uses custom interpolation format" do
      yaml_data = {"en" => {"greeting" => "Hello, %{name}!"}}
      converter = described_class.new(yaml_data, locale: :en)

      expect(converter.convert).to eq({"greeting" => "Hello, ${name}!"})
    end
  end
end
