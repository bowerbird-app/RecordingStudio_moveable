> **Architecture Documentation**
> *   **Canonical Source:** [bowerbird-app/RecordingStudio_moveable](https://github.com/bowerbird-app/RecordingStudio_moveable/tree/main/docs/recording_studio_moveable)
> *   **Last Updated:** April 28, 2026
>
> *Maintainers: Please update the date above when modifying this file.*

---

# RecordingStudioMoveable Configuration

This document explains how to configure **RecordingStudioMoveable** in your host Rails application.

---

## Quick Start

RecordingStudioMoveable owns move behavior. In built-in authorization mode, access resolution comes from `recording_studio_accessible`, not from legacy `recording_studio` access-check helpers.

After installing the gem, run the install generator:

```bash
rails generate recording_studio_moveable:install
```

This will:

1. Mount the engine in your routes (`/recording_studio_moveable` by default).
2. Create `config/initializers/recording_studio_moveable.rb` with example settings.
3. Optionally create `config/recording_studio_moveable.yml` for environment-specific configuration.

---

## Configuration Options

| Option              | Type    | Default                          | Description                                 |
|---------------------|---------|----------------------------------|---------------------------------------------|
| `api_key`           | String  | `ENV["RECORDING_STUDIO_MOVEABLE_API_KEY"]` | API key for external service integration.  |
| `enable_feature_x`  | Boolean | `false`                          | Toggle optional feature X.                 |
| `timeout`           | Integer | `5`                              | Timeout (seconds) for external calls.      |

---

## Move Redirect Behavior

Move redirects are configured separately from the top-level engine settings:

```ruby
RecordingStudio::Moveable.configure do |config|
  config.default_redirect_path = "/"
  config.default_redirect_mode = :previous_page
end
```

### Redirect Options

| Option                  | Type                 | Default           | Description |
|-------------------------|----------------------|-------------------|-------------|
| `default_redirect_path` | String               | `"/"`            | Fallback path when no safer or more specific redirect target is available. |
| `default_redirect_mode` | Symbol or String     | `:previous_page`  | Default post-move target mode. Supported values: `previous_page`, `moved_record`, `destination`, `root`. |
| `redirect_resolver`     | Callable or `nil`    | `nil`             | Optional hook for resolving a record's host-app URL when the default polymorphic route is not enough. |

### Redirect Precedence

When a move succeeds, the redirect target is chosen in this order:

1. A safe same-origin `redirect_to` request parameter.
2. The selected `redirect_mode` request parameter, or `default_redirect_mode` if none was passed.
3. The request referer when the mode is `previous_page`.
4. `default_redirect_path`.

### Request Parameters

You can override redirect behavior per request:

```ruby
recording_studio_moveable.move_recording_path(
  recording_id: recording.id,
  redirect_mode: "moved_record"
)
```

Supported `redirect_mode` values:

- `previous_page`: return to the page that launched the move UI.
- `moved_record`: follow the record that was moved.
- `destination`: go to the destination record after the move.
- `root`: go straight to `default_redirect_path`.

If you pass both `redirect_to` and `redirect_mode`, the explicit `redirect_to` value wins.

### Custom Redirect Resolver

By default, `moved_record` and `destination` use `polymorphic_path(recording.recordable)`. If your host app needs custom routing, provide a resolver:

```ruby
RecordingStudio::Moveable.configure do |config|
  config.default_redirect_mode = :moved_record

  config.redirect_resolver = lambda do |recording:, helpers:, fallback:, mode:|
    case recording.recordable
    when RecordingStudioFolder
      helpers.recording_studio_folder_path(recording.recordable)
    when RecordingStudioPage
      helpers.recording_studio_page_path(recording.recordable)
    else
      fallback
    end
  end
end
```

The resolver receives:

- `recording`: the `RecordingStudio::Recording` being resolved.
- `helpers`: host-app route helpers from `main_app`.
- `fallback`: the default polymorphic path, if one could be generated.
- `mode`: the active redirect mode (`moved_record` or `destination`).

---

## Configuration Methods

### 1. Ruby Initializer (Recommended)

Edit `config/initializers/recording_studio_moveable.rb`:

```ruby
RecordingStudioMoveable.configure do |config|
  config.api_key          = ENV["RECORDING_STUDIO_MOVEABLE_API_KEY"]
  config.enable_feature_x = true
  config.timeout          = 10
end
```

This approach is flexible and allows dynamic values, environment variables, and Rails credentials.

## Access Integration

Built-in move authorization expects `recording_studio_accessible` to be installed and configured for your root recordables.

In that mode:

- move source visibility requires `:edit`
- move destination visibility requires `:edit`
- access roles are resolved through `RecordingStudioAccessible::DirectAccessQuery`
- hosts should seed or manage grants through Accessible APIs such as `RecordingStudioAccessible.grant_access`

If your app is still on a `recording_studio` release that ships access tables or constants, Accessible can run in compatibility mode. That compatibility layer does not change the public integration point for move authorization: RecordingStudioMoveable still queries access through Accessible.

### 2. YAML Configuration

If you prefer environment-specific static settings, create `config/recording_studio_moveable.yml`:

```yaml
development:
  api_key: "dev-key"
  enable_feature_x: true
  timeout: 5

production:
  api_key: <%= ENV["RECORDING_STUDIO_MOVEABLE_API_KEY"] %>
  enable_feature_x: false
  timeout: 5
```

The engine loads this file automatically via `Rails.application.config_for(:recording_studio_moveable)`.

### 3. `config.x` Namespace

You can also set values in `config/application.rb` or environment files:

```ruby
# config/environments/production.rb
config.x.recording_studio_moveable.api_key = ENV["RECORDING_STUDIO_MOVEABLE_API_KEY"]
config.x.recording_studio_moveable.timeout = 10
```

---

## Load Order & Precedence

Configuration is merged in the following order (later sources override earlier ones):

1. **Defaults** – defined in `RecordingStudioMoveable::Configuration#initialize`.
2. **YAML** – `config/recording_studio_moveable.yml` loaded via `config_for`.
3. **`config.x.recording_studio_moveable`** – values set in Rails config files.
4. **Initializer** – `RecordingStudioMoveable.configure` block in `config/initializers/recording_studio_moveable.rb`.

> **Tip:** For most use cases, stick with the Ruby initializer and use environment variables for secrets.

---

## Accessing Configuration at Runtime

```ruby
RecordingStudioMoveable.configuration.api_key
# => "your-api-key"

RecordingStudioMoveable.configuration.enable_feature_x
# => true

RecordingStudioMoveable.configuration.to_h
# => { api_key: "...", enable_feature_x: true, timeout: 5 }
```

You can access these values from anywhere in your application or from within the engine's controllers, models, and jobs.

---

## Secret Management

For sensitive values like `api_key`, we recommend:

- **Environment variables** – `ENV["RECORDING_STUDIO_MOVEABLE_API_KEY"]`
- **Rails credentials** – `Rails.application.credentials.recording_studio_moveable[:api_key]`

Avoid committing secrets to version control. The generator templates use `ENV` by default to encourage this practice.

---

## Extending Configuration

To add new options:

1. Add `attr_accessor` in `lib/recording_studio_moveable/configuration.rb`.
2. Set a sensible default in `#initialize`.
3. Update `#to_h` if you want the option included in hash export.
4. Document the new option in this file and in the initializer template.

---

## Troubleshooting

| Issue                                  | Solution                                                                 |
|----------------------------------------|--------------------------------------------------------------------------|
| YAML not loading                       | Ensure `config/recording_studio_moveable.yml` exists and has valid YAML syntax.       |
| Initializer values not applied         | Make sure the initializer runs after the engine initializer (default).   |
| `config.x` values ignored              | Verify you're setting them in the correct environment file.             |

---

## Files Reference

| File                                                        | Purpose                                      |
|-------------------------------------------------------------|----------------------------------------------|
| `lib/recording_studio_moveable/configuration.rb`                         | Configuration class with defaults.           |
| `lib/recording_studio_moveable/engine.rb`                                | Engine initializer that loads host config.   |
| `lib/generators/recording_studio_moveable/install/install_generator.rb`  | Install generator that creates config files. |
| `lib/generators/recording_studio_moveable/install/templates/`            | Templates for initializer and YAML files.    |

---

Happy configuring! 🎉
