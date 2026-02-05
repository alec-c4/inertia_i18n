## [Unreleased]

## [0.4.2] - 2026-02-05

### Fixed

- `watch` command not detecting changes when `source_paths` contains `Pathname` objects

## [0.4.1] - 2026-02-05

### Changed

- Default `config.locales` now uses `I18n.available_locales` instead of hardcoded `[:en]`
- Generated initializer shows commented example for overriding locales

## [0.4.0] - 2026-01-28

### Added

- `normalize` command now sorts keys in YAML locale files in addition to JSON files
- `InertiaI18n::Normalizer` class to handle file normalization logic

## [0.3.0] - 2026-01-19

### Added

- Configuration options for tuning health checks: `key_properties`, `sibling_detection`, and`missing_key_filters`
- Support for extracting translation keys from object properties (e.g., `titleKey: "some.key"`)
- Support for detecting string concatenation patterns as dynamic keys (e.g., `t('prefix.' + var)`)

### Improved

- Health Checker now intelligently handles i18next plural suffixes:
  - Missing check: `t('key', { count: n })` won't report missing if `key_one`/`key_other` exist
  - Unused check: `key_one`/`key_other` won't report unused if base `key` is used in code
- Added "sibling detection" to automatically handle enum-like keys (e.g., if `status.open` is used, all`status.*` are considered used)
- Added default filters for false-positive missing keys (ignores short keys, keys without dots, URLs,constants, incomplete keys ending with `.`)

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
