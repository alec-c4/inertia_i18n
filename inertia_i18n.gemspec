# frozen_string_literal: true

require_relative "lib/inertia_i18n/version"

Gem::Specification.new do |spec|
  spec.name = "inertia_i18n"
  spec.version = InertiaI18n::VERSION
  spec.authors = ["Alexey Poimtsev"]
  spec.email = ["alexey.poimtsev@gmail.com"]

  spec.summary = "Translation management for Inertia.js applications"
  spec.description = "Convert Rails YAML locales to i18next JSON, scan frontend code for translation usage, " \
                     "detect missing/unused keys, and check locale synchronization. " \
                     "Supports Svelte, React, and Vue frontends."
  spec.homepage = "https://github.com/alec-c4/inertia_i18n"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/alec-c4/inertia_i18n"
  spec.metadata["changelog_uri"] = "https://github.com/alec-c4/inertia_i18n/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    Dir["{lib,exe}/**/*", "LICENSE.txt", "README.md", "CHANGELOG.md"].reject { |f| File.directory?(f) }
  end
  spec.bindir = "exe"
  spec.executables = ["inertia-i18n"]
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "~> 1.0"
  spec.add_dependency "railties", ">= 7.0"
  spec.add_dependency "listen", "~> 3.0"

  spec.add_development_dependency "bundler", ">= 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "simplecov", "~> 0.21"
  spec.add_development_dependency "appraisal"
  spec.add_development_dependency "lefthook"
end
