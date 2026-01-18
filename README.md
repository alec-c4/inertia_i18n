# InertiaI18n

Translation management for Inertia.js applications with Rails backend

[![Gem Version](https://badge.fury.io/rb/inertia_i18n.svg)](https://badge.fury.io/rb/inertia_i18n)
[![Build Status](https://github.com/alec-c4/inertia_i18n/actions/workflows/main.yml/badge.svg)](https://github.com/alec-c4/inertia_i18n/actions)

## The Problem

Inertia.js applications have a split architecture:

- **Backend (Rails):** Uses YAML locale files (`config/locales/*.yml`)
- **Frontend (React/Svelte/Vue):** Uses i18next JSON files

This creates several challenges:

1. **Duplicate management:** Maintaining translations in two formats
2. **Sync issues:** Keys in YAML but missing in JSON (or vice versa)
3. **No usage tracking:** Unused translation keys accumulate
4. **Manual process:** Converting YAML → JSON by hand is error-prone

Existing tools like [i18n-tasks](https://github.com/glebm/i18n-tasks) only handle Rails/backend translations.

## The Solution

InertiaI18n provides:

- **YAML → JSON conversion** with interpolation mapping (`%{var}` → `{{var}}`)
- **AST-based scanning** to find translation usage in `.svelte`, `.tsx`, `.vue` files
- **Health checks** to detect missing, unused, and unsynchronized keys
- **Watch mode** for automatic regeneration during development
- **Rails integration** via initializers and rake tasks

**One source of truth:** Rails YAML files, with JSON auto-generated.

---

## Installation

Add to your Gemfile:

```ruby
gem 'inertia_i18n'
```

Run the installer:

```bash
rails generate inertia_i18n:install
```

This generator will:

1. Create the locale directory structure (`config/locales/frontend`, `config/locales/backend`).
2. Generate the configuration file (`config/initializers/inertia_i18n.rb`).
3. Create a sample locale file.
4. Detect your frontend framework (React, Vue, or Svelte) and add necessary dependencies (e.g., `react-i18next`) to your `package.json`.

---

## Recommended Directory Structure

To avoid conflicts between backend and frontend translation keys, it is recommended to separate your locale files into subdirectories:

```
config/
└── locales/
    ├── backend/      # Rails-specific translations
    │   ├── en.yml
    │   └── ru.yml
    ├── frontend/     # Frontend-specific translations
    │   ├── common.en.yml
    │   ├── pages.en.yml
    │   └── pages.ru.yml
    └── en.yml          # Optional: shared or legacy keys
```

By default, InertiaI18n will look for YAML files in `config/locales/frontend`. You can customize this using the `source_paths` configuration.

---

## Quick Start

### 1. Configure

The installer creates a default configuration file. You can customize it in `config/initializers/inertia_i18n.rb`.

```ruby
# config/initializers/inertia_i18n.rb
InertiaI18n.configure do |config|
  # Recommended: point to a dedicated frontend folder
  config.source_paths = [Rails.root.join('config', 'locales', 'frontend')]

  config.target_path = Rails.root.join('app', 'frontend', 'locales')
  config.locales = [:en, :ru]

  # Scan paths are automatically set based on your detected framework
  config.scan_paths = [
    Rails.root.join('app', 'frontend', '**', '*.{svelte,tsx,vue}')
  ]
end
```

### 2. Convert YAML to JSON

```bash
# One-time conversion
bundle exec rake inertia_i18n:convert

# Watch mode (auto-convert on YAML changes)
bundle exec rake inertia_i18n:watch
```

### 3. Check Translation Health

The recommended way to check translation health is by running the generated test as part of your test suite. See the [CI Integration](#ci-integration) section for details.

You can also run a manual check from the command line:

```bash
# Find missing, unused, and out-of-sync keys
bundle exec rake inertia_i18n:health
```

---

## CLI Usage

All CLI commands load the Rails environment, so they have access to your application's configuration and behave identically to the `rake` tasks.

```bash
# Generate a new configuration file
inertia_i18n init

# Convert YAML to JSON
inertia_i18n convert

# Convert specific locale
inertia_i18n convert --locale=ru

# Scan frontend code for translation usage
inertia_i18n scan

# Check translation health
inertia_i18n health

# Sort and format JSON locale files
inertia_i18n normalize

# Watch for changes and auto-convert
inertia_i18n watch
```

---

## Features

### YAML → JSON Conversion

**Input (Rails YAML):**

```yaml
# config/locales/en.yml
en:
  user:
    greeting: "Hello, %{name}!"
    items:
      one: "1 item"
      other: "%{count} items"
```

**Output (i18next JSON):**

```json
{
  "user": {
    "greeting": "Hello, {{name}}!",
    "items_one": "1 item",
    "items_other": "{{count}} items"
  }
}
```

### Smart Scanning

Detects translation usage in:

- Svelte: `{t('key')}` and `t('key')` in `<script>`
- React: `{t('key')}` in JSX
- Vue: `{{ t('key') }}` and `t('key')` in script

Handles:

- Static keys: `t('user.greeting')`
- Template literals: `t(\`user.\${type}.title\`)` (flagged for review)
- Dynamic patterns: `t(keyVariable)` (flagged for review)

### Health Checks

| Check            | Description                                      |
| ---------------- | ------------------------------------------------ |
| **Missing Keys** | Used in code but not in JSON (breaks app)        |
| **Unused Keys**  | In JSON but never used (bloat)                   |
| **Locale Sync**  | Key exists in `en.json` but missing in `ru.json` |

### Watch Mode

Auto-regenerates JSON when YAML files change:

```bash
bundle exec rake inertia_i18n:watch

# Output:
👀 Watching config/locales for YAML changes...
📝 Detected locale file changes...
   Changed: config/locales/hr.en.yml
🔄 Regenerating JSON files...
✅ Done!
```

---

## CI Integration

The best way to ensure your translations stay healthy is to check them in your Continuous Integration (CI) pipeline.

### Test-based Health Check (Recommended)

Generate a dedicated test file that runs the health check as part of your test suite:

```bash
# For RSpec
rails g inertia_i18n:test
# Creates spec/inertia_i18n_health_spec.rb

# For Minitest
# Creates test/inertia_i18n_health_test.rb
```

Now, your existing CI command will automatically catch translation issues:

```bash
# Run your full test suite
bundle exec rspec
# or
bundle exec rails test
```

When issues are found, the test will fail with a detailed report:

```
Failure/Error: fail message.join("\n")

RuntimeError:

  Translation health check failed!

  Missing Keys (1):
    - home.title

  Unused Keys (1):
    - unused.key

  Locale Synchronization Issues (2):
    - unused.key (in ru)
    - home.title (in ru)
```

### GitHub Actions Example

```yaml
# .github/workflows/ci.yml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true

      # Run the full test suite, which now includes the translation health check
      - name: Run tests
        run: bundle exec rspec
```

---

## Compatibility with i18n-tasks

If you use [i18n-tasks](https://github.com/glebm/i18n-tasks) for your backend translations, it might flag your frontend keys as "unused" or "missing". To prevent this, configure `i18n-tasks` to ignore the frontend locale directory.

Add this to your `config/i18n-tasks.yml`:

```yaml
# config/i18n-tasks.yml
data:
  read:
    - "config/locales/backend/**/*.yml" # Read only backend locales
    - "config/locales/*.yml" # Optional: shared keys
```

Alternatively, you can exclude the frontend directory:

```yaml
# config/i18n-tasks.yml
ignore:
  - "frontend.*" # Ignore all keys starting with "frontend." (if namespaced)
```

---

## Configuration Reference

```ruby
InertiaI18n.configure do |config|
  # Source directories for your frontend YAML files.
  # Default: ['config/locales/frontend']
  config.source_paths = [
    'config/locales/frontend',
    'config/locales/common'
  ]
  config.source_pattern = '**/*.{yml,yaml}'

  # Target: i18next JSON files
  config.target_path = 'app/frontend/locales'

  # Locales to process
  config.locales = [:en, :ru, :de]

  # Frontend paths to scan
  config.scan_paths = [
    'app/frontend/**/*.{js,ts,jsx,tsx,svelte,vue}'
  ]

  # Interpolation conversion
  config.interpolation = { from: '%{', to: '{{' }

  # Flatten nested keys (default: false)
  config.flatten_keys = false

  # Ignore patterns (don't scan these files)
  config.ignore_patterns = [
    '**/node_modules/**',
    '**/vendor/**',
    '**/*.test.{js,ts}'
  ]
end
```

---

## Comparison with Alternatives

| Feature                 | InertiaI18n | i18n-tasks        | i18next-parser       |
| ----------------------- | ----------- | ----------------- | -------------------- |
| Rails YAML support      | ✅          | ✅                | ❌                   |
| i18next JSON support    | ✅          | ❌                | ✅                   |
| YAML → JSON conversion  | ✅          | ❌                | ❌                   |
| Frontend usage scanning | ✅          | ❌                | ✅ (extraction only) |
| Missing keys detection  | ✅          | ✅ (backend only) | ✅ (frontend only)   |
| Unused keys detection   | ✅          | ✅ (backend only) | ❌                   |
| Locale sync check       | ✅          | ✅                | ✅                   |
| Watch mode              | ✅          | ❌                | ✅                   |
| Rails integration       | ✅          | ✅                | ❌                   |
| Inertia.js specific     | ✅          | ❌                | ❌                   |

**InertiaI18n = i18n-tasks + i18next-parser + YAML↔JSON bridge**

---

## Development

```bash
# Clone repository
git clone https://github.com/alec-c4/inertia_i18n.git
cd inertia_i18n

# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Run locally in your Rails app
# Add to Gemfile:
gem 'inertia_i18n', path: '../inertia_i18n'
```

---

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests (TDD approach)
4. Implement the feature
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

---

## License

MIT License - see [LICENSE.txt](LICENSE.txt)

---

## Credits

Created by [Alexey Poimtsev](https://alec-c4.com)

Inspired by:

- [i18n-tasks](https://github.com/glebm/i18n-tasks) - Rails i18n management
- [i18next-parser](https://github.com/i18next/i18next-parser) - Frontend key extraction
- Real-world pain from managing translations in Inertia.js apps
