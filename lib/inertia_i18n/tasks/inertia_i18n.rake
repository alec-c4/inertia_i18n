# frozen_string_literal: true

namespace :inertia_i18n do
  desc "Convert YAML locales to JSON"
  task convert: :environment do
    require "inertia_i18n/cli"
    InertiaI18n::Cli.new.convert
  end

  desc "Watch YAML locales for changes and auto-convert"
  task watch: :environment do
    require "inertia_i18n/cli"
    InertiaI18n::Cli.new.watch
  end

  desc "Scan frontend code for translation key usage"
  task scan: :environment do
    require "inertia_i18n/cli"
    InertiaI18n::Cli.new.scan
  end

  desc "Check translation health (missing, unused, unsync)"
  task health: :environment do
    require "inertia_i18n/cli"
    InertiaI18n::Cli.new.health
  end

  desc "Sort and format JSON locale files"
  task normalize: :environment do
    require "inertia_i18n/cli"
    InertiaI18n::Cli.new.normalize
  end
end
