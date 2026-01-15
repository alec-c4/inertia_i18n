# frozen_string_literal: true

RSpec.describe InertiaI18n::HealthChecker do
  let(:locales_path) { File.expand_path("../fixtures/locales", __dir__) }
  let(:frontend_path) { File.expand_path("../fixtures/frontend", __dir__) }

  before do
    FileUtils.mkdir_p(locales_path)
    InertiaI18n.configure do |config|
      config.scan_paths = ["#{frontend_path}/**/*.{js,ts,svelte,jsx,tsx,vue}"]
      config.target_path = locales_path
    end
  end

  after do
    FileUtils.rm_rf(locales_path)
    InertiaI18n.reset_configuration!
  end

  describe "#check!" do
    subject(:checker) { described_class.new.check! }

    context "with healthy translations" do
      before do
        File.write(
          File.join(locales_path, "en.json"),
          JSON.pretty_generate({
            "common" => {"hello" => "Hello", "goodbye" => "Goodbye"},
            "status" => {"active" => "Active", "pending" => "Pending"},
            "svelte" => {"profile_title" => "Svelte Profile", "greeting" => "Hello Svelte!", "dynamic" => {"test" => "Svelte Test"}},
            "javascript" => {"message" => "JS Message", "dynamic" => {"test" => "JS Test"}},
            "typescript" => {"message" => "TS Message", "dynamic" => {"test" => "TS Test"}},
            "react" => {"profile_title" => "React Profile", "greeting" => "Hello React!", "dynamic" => {"test" => "React Test"}},
            "vue" => {"profile_title" => "Vue Profile", "greeting" => "Hello Vue!", "script_key" => "Key from script", "dynamic" => {"test" => "Vue Test"}}
          })
        )
      end

      it "reports no issues" do
        expect(checker).to be_healthy
      end
    end

    context "with missing keys" do
      before do
        File.write(
          File.join(locales_path, "en.json"),
          JSON.pretty_generate({
            "common" => {"hello" => "Hello", "goodbye" => "Goodbye"},
            "status" => {"active" => "Active"}
          })
        )
      end

      it "detects missing keys" do
        missing_keys = checker.issues[:missing].map { |i| i[:key] }
        expect(missing_keys).to include("svelte.profile_title")
      end

      it "marks severity as error" do
        checker = described_class.new.check!
        expect(checker.issues[:missing].first[:severity]).to eq(:error)
      end
    end

    context "with unused keys" do
      before do
        File.write(
          File.join(locales_path, "en.json"),
          JSON.pretty_generate({
            "common" => {"hello" => "Hello", "goodbye" => "Goodbye"},
            "user" => {"profile" => {"title" => "Profile"}},
            "status" => {"active" => "Active"},
            "unused" => {"key" => "Not used anywhere"}
          })
        )

        File.write(
          File.join(locales_path, "ru.json"),
          JSON.pretty_generate({
            "common" => {"hello" => "Привет", "goodbye" => "Пока"},
            "user" => {"profile" => {"title" => "Профиль"}},
            "status" => {"active" => "Активен"},
            "unused" => {"key" => "Не используется"}
          })
        )
      end

      it "detects unused keys" do
        checker = described_class.new.check!
        unused_keys = checker.issues[:unused].map { |i| i[:key] }

        expect(unused_keys).to include("unused.key")
      end

      it "marks severity as warning" do
        checker = described_class.new.check!
        unused = checker.issues[:unused].find { |i| i[:key] == "unused.key" }
        expect(unused[:severity]).to eq(:warning)
      end
    end

    context "with locale sync issues" do
      before do
        InertiaI18n.configure do |config|
          config.locales = %i[en ru]
        end

        File.write(
          File.join(locales_path, "en.json"),
          JSON.pretty_generate({
            "common" => {"hello" => "Hello", "goodbye" => "Goodbye"},
            "user" => {"profile" => {"title" => "Profile"}},
            "status" => {"active" => "Active"},
            "only_in_en" => "English only"
          })
        )

        # ru.json missing 'only_in_en', has extra 'only_in_ru'
        File.write(
          File.join(locales_path, "ru.json"),
          JSON.pretty_generate({
            "common" => {"hello" => "Привет", "goodbye" => "Пока"},
            "user" => {"profile" => {"title" => "Профиль"}},
            "status" => {"active" => "Активен"},
            "only_in_ru" => "Только на русском"
          })
        )
      end

      it "detects keys missing in secondary locale" do
        checker = described_class.new.check!
        unsync = checker.issues[:unsync]

        missing_in_ru = unsync.find { |i| i[:key] == "only_in_en" && i[:locale] == :ru }
        expect(missing_in_ru).not_to be_nil
        expect(missing_in_ru[:severity]).to eq(:error)
      end

      it "detects extra keys in secondary locale" do
        checker = described_class.new.check!
        unsync = checker.issues[:unsync]

        extra_in_ru = unsync.find { |i| i[:key] == "only_in_ru" && i[:locale] == :ru }
        expect(extra_in_ru).not_to be_nil
        expect(extra_in_ru[:severity]).to eq(:warning)
      end
    end

    context "with dynamic patterns" do
      before do
        File.write(
          File.join(locales_path, "en.json"),
          JSON.pretty_generate({
            "common" => {"hello" => "Hello", "goodbye" => "Goodbye"},
            "user" => {"profile" => {"title" => "Profile"}},
            "status" => {"active" => "Active", "pending" => "Pending",
                         "completed" => "Completed"}
          })
        )

        File.write(
          File.join(locales_path, "ru.json"),
          JSON.pretty_generate({
            "common" => {"hello" => "Привет", "goodbye" => "Пока"},
            "user" => {"profile" => {"title" => "Профиль"}},
            "status" => {"active" => "Активен", "pending" => "В ожидании",
                         "completed" => "Завершён"}
          })
        )
      end

      it "does not mark dynamic pattern keys as unused" do
        checker = described_class.new.check!
        unused_keys = checker.issues[:unused].map { |i| i[:key] }

        # status.* keys should not be marked unused because of t(`status.${var}`)
        expect(unused_keys).not_to include("status.active")
        expect(unused_keys).not_to include("status.pending")
      end
    end
  end

  describe "#healthy?" do
    before do
      File.write(File.join(locales_path, "en.json"), "{}")
      File.write(File.join(locales_path, "ru.json"), "{}")
    end

    it "returns true when no issues" do
      checker = described_class.new
      # Manually set empty issues to test the method
      checker.instance_variable_set(:@issues, {missing: [], unused: [], unsync: []})
      expect(checker).to be_healthy
    end

    it "returns false when issues exist" do
      checker = described_class.new.check!
      expect(checker).not_to be_healthy
    end
  end

  describe "#summary" do
    before do
      File.write(
        File.join(locales_path, "en.json"),
        JSON.pretty_generate({"common" => {"hello" => "Hello"}})
      )
      File.write(
        File.join(locales_path, "ru.json"),
        JSON.pretty_generate({"common" => {"hello" => "Привет"}})
      )
    end

    it "returns summary hash" do
      checker = described_class.new.check!
      summary = checker.summary

      expect(summary).to include(:total_errors, :total_warnings, :healthy)
    end
  end
end

RSpec.describe InertiaI18n::LocaleLoader do
  let(:fixtures_path) { File.expand_path("../fixtures/locales", __dir__) }

  before do
    InertiaI18n.configure do |config|
      config.target_path = fixtures_path
      config.locales = %i[en]
    end

    FileUtils.mkdir_p(fixtures_path)
    File.write(
      File.join(fixtures_path, "en.json"),
      JSON.pretty_generate({
        "common" => {"hello" => "Hello"},
        "user" => {"name" => "Name", "email" => "Email"}
      })
    )
  end

  after do
    InertiaI18n.reset_configuration!
    FileUtils.rm_rf(fixtures_path)
  end

  describe ".load_all" do
    it "loads all locale JSON files" do
      locales = described_class.load_all
      expect(locales[:en]).to be_a(Hash)
      expect(locales[:en]["common"]["hello"]).to eq("Hello")
    end
  end

  describe ".extract_keys" do
    it "flattens nested keys with dot notation" do
      data = {"common" => {"hello" => "Hello"}, "user" => {"name" => "Name"}}
      keys = described_class.extract_keys(data)

      expect(keys).to include("common.hello", "user.name")
    end

    it "handles deeply nested structures" do
      data = {"a" => {"b" => {"c" => "value"}}}
      keys = described_class.extract_keys(data)

      expect(keys).to include("a.b.c")
    end
  end
end
