## [Unreleased]

## [0.2.0] - 2026-01-18

### Added

- `watch` command (CLI and Rake) to auto-convert YAML locales on change
- Rake tasks for all CLI commands (`convert`, `scan`, `health`, `normalize`)
- `InertiaI18n::Railtie` to automatically load Rake tasks in Rails apps
- `listen` dependency for file watching

### Fixed

- Scanner incorrectly matching words ending in 't' (e.g. `split`) as translation calls

## [0.1.3] - 2026-01-16

- Fix `RSpec/SpecFilePathFormat` lint error in generated test file

## [0.1.2] - 2026-01-16

- Fix `LocalJumpError` in generated RSpec test file

## [0.1.1] - 2026-01-16

- Change generated test file paths to `spec/inertia_i18n_spec.rb` and `test/inertia_i18n_test.rb`

## [0.1.0] - 2026-01-16

- Initial release
