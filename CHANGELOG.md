## [Unreleased]

## [0.8.0] - 2026-02-27

### Added

- **Full Pluralization Support:** `Converter` now fully supports parsing `zero`, `one`, `two`, `few`, `many`, and `other` plural forms from YAML into i18next JSON syntax.
- **Smart Plural Syncing:** `health` check `unsync` and `unused` commands now group plural keys (e.g. `apples_one`, `apples_few`) under a single `apples (plural forms)` message. This prevents false positives when locales have differing sets of pluralization rules (e.g. Russian vs. English) and drastically reduces warning noise.

## [0.7.0] - 2026-02-27

### Added

- **Dynamic Keys Configuration**: Added `dynamic_keys` configuration property to expand dynamic patterns into explicit static keys. This allows the scanner to check for missing variants of dynamic keys (e.g. `status.active`, `status.inactive`) and mark them as used. Supported in both Ruby initializer and YAML configuration formats.

## [0.6.2] - 2026-02-23

### Fixed

- Install generator now creates sample locale files (`common.{locale}.yml`) for **all configured locales**, not just English. Previously, only `common.en.yml` was created, causing `ru.json` (and other non-English locales) to be generated empty after `rake inertia_i18n:convert`.

### Changed

- Generated initializer now includes `config.ignore_unused = ["common"]` by default so that the sample `common.*` keys created by the generator don't trigger unused-key warnings in the RSpec health check.

## [0.6.1] - 2026-02-10

### Fixed

- Crash in `health` command when `dynamic_patterns` is missing from YAML config
- Support for multiple keys in single-line magic comments (`// inertia-i18n-use key1 key2`)

## [0.6.0] - 2026-02-09

### Added

- **Context Awareness**: `missing` and `unused` commands now report the file path and line number where the key was found (e.g., `app/frontend/User.vue:42`).
- **Magic Comments**: Support for `// inertia-i18n-use key.name` and `/* inertia-i18n-use key.name */` to mark dynamic keys as used.
- **i18n-tasks Compatibility**:
    - Support for `// i18n-tasks-use key.name` comments (interoperability).
    - `InertiaI18n::I18nTasks::Scanner` adapter class to allow `i18n-tasks` to use `inertia_i18n`'s frontend scanning logic.
- **Robust CLI**: `inertia-i18n` command now correctly loads the library in non-Rails environments.

### Fixed

- Scanner adapter now returns data in the format `i18n-tasks` expects (including source location).

## [0.5.0] - 2026-02-06

### Added

- `missing` CLI command and rake task to find missing translation keys independently
- `unused` CLI command and rake task to find unused translation keys independently
- YML config support: `config/inertia_i18n.yml` as alternative to Ruby initializer
- `Configuration#load_from_yaml` with automatic type coercion (locales → symbols, exclude_patterns → Regexp)
- Auto-detection of YML config in CLI and Rails (via Railtie initializer)
- `init --format yaml` option to generate YML config template
- `HealthChecker#check!(checks:)` parameter for running selective checks (`:missing`, `:unused`, `:unsync`)

### Changed

- **Breaking:** CLI executable renamed from `inertia_i18n` to `inertia-i18n` (matching i18n-tasks naming convention)

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
