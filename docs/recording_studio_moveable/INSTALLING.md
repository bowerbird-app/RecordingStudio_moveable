> **Architecture Documentation**
> *   **Canonical Source:** [bowerbird-app/RecordingStudio_moveable](https://github.com/bowerbird-app/RecordingStudio_moveable/tree/main/docs/recording_studio_moveable)
> *   **Last Updated:** August 16, 2026
>
> *Maintainers: Please update the date above when modifying this file.*

---

# Installing in a Host Application

This guide explains how to install the RecordingStudioMoveable engine in your Rails application.

---

## Prerequisites

- Rails 8.1+ application
- RecordingStudio core 3.0+
- PostgreSQL (recommended for UUID compatibility)
- TailwindCSS (optional, for styling engine views)

---

## Installation Steps

### 1. Add the Gem

Add to your `Gemfile`:

```ruby
gem "recording_studio", "~> 3.0"
gem "recording_studio_accessible", "~> 0.3"
# From GitHub
gem "recording_studio_moveable", github: "bowerbird-app/RecordingStudio_moveable"

# Or from a local path (for development)
gem "recording_studio_moveable", path: "../recording_studio_moveable"

# Or from RubyGems (after publishing)
gem "recording_studio_moveable"
```

### 2. Install Dependencies

```bash
bundle install
```

### 2.5 Install Access Integration for Built-In Authorization

RecordingStudioMoveable depends on `recording_studio_accessible` for built-in authorization. Keep it in your Gemfile explicitly if your application manages access grants directly:

```ruby
gem "recording_studio_accessible", "~> 0.3"
```

Then run the Accessible setup if your application does not already have the required access tables:

```bash
bin/rails generate recording_studio_accessible:install
bin/rails generate recording_studio_accessible:migrations
bin/rails db:migrate
```

Enable the Accessible capability on root recordables that should accept direct grants and expose the acting principal through `Current.actor` or `RecordingStudioMoveable.configure`.

### 2.6 Declare RecordingStudio Core Hierarchy

RecordingStudio core owns structural hierarchy in V3. Every configured recordable type should declare `recording_studio_recordable`, and child recordables should list allowed parent types there:

```ruby
class Workspace < ApplicationRecord
  recording_studio_recordable label: "Workspace", root: true, allowed_parent_types: []

  RecordingStudio.enable_capability(:accessible, on: self)
end

class RecordingStudioPage < ApplicationRecord
  recording_studio_recordable \
    label: "Page",
    root: false,
    allowed_parent_types: ["Workspace", "RecordingStudioFolder"]

  include RecordingStudio::Capabilities::Moveable.enabled(allow_cross_root: true)
end
```

Moveable only enables move behavior and move-specific options such as `allow_cross_root:`. It does not define destination parent types; the destination picker uses core declarations plus same-root/cross-root rules, self/descendant protection, and authorization filtering.

### 2.7 Optional RecordingStudio API Action

Moveable does not require `recording_studio_api` at runtime. To expose moves over the programmable API, install
RecordingStudioApi in the host application, then run its generators from the host application directory:

```bash
bin/rails generate recording_studio_api:install
bin/rails generate recording_studio_api:migrations
bin/rails generate recording_studio_api:scalar_docs moveable_api \
  --mount-path=/recording_studio_api/docs/scalar \
  --api-mount-path=/recording_studio_api \
  --api-surface=public \
  --access=authenticated \
  --layout=recording_studio/default_layout
bin/rails db:migrate
```

RecordingStudio API 0.4.0 also requires each root type that may receive API access to enable
`RecordingStudio.enable_capability(:api_access_point, on: self)` alongside `:accessible`.

Configure API version profiles with `api.use :moveable, "~> 1.0"` when the host uses profiles, and explicitly
allow the action on each published type with
`RecordingStudioApi.register_recordable_type_api("RecordingStudioPage", capability_actions: %i[move])`. See
[API.md](API.md) for the dependency declarations, endpoint, parameter contract, and authorization behavior.

### 3. Run the Install Generator

```bash
rails generate recording_studio_moveable:install
```

This will:
1. **Mount the engine** at `/recording_studio_moveable` in your `config/routes.rb`
2. **Create a configuration initializer** at `config/initializers/recording_studio_moveable.rb`
3. **Configure Tailwind** to include engine views (if Tailwind is detected)
4. **Display post-installation instructions**

---

## What the Generator Does

### Routes

Adds this line to `config/routes.rb`:

```ruby
mount RecordingStudioMoveable::Engine, at: "/recording_studio_moveable"
```

### Configuration

Creates `config/initializers/recording_studio_moveable.rb`:

```ruby
RecordingStudioMoveable.configure do |config|
  # config.api_key = ENV["RECORDING_STUDIO_MOVEABLE_API_KEY"]
  # config.enable_feature_x = false
  # config.timeout = 5
end

RecordingStudio::Moveable.configure do |config|
  # config.default_redirect_mode = :previous_page
  # config.default_redirect_path = "/"
  # config.redirect_resolver = ->(recording:, helpers:, fallback:, mode:) { fallback }
end
```

See [CONFIGURATION.md](CONFIGURATION.md) for all options.

Built-in authorization uses Recording Studio Accessible's public query APIs. It does not depend on legacy `RecordingStudio::Services::AccessCheck` helpers.

### Tailwind CSS

If your app uses Tailwind, the generator adds a `@source` directive to include engine views:

```css
@source "../../vendor/bundle/**/recording_studio_moveable/app/views/**/*.erb";
```

This ensures Tailwind scans the engine's templates for class names during CSS compilation.

---

## Manual Installation

If you prefer not to use the generator:

### Mount the Engine

Add to `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  mount RecordingStudioMoveable::Engine, at: "/recording_studio_moveable"
  # ... your other routes
end
```

### Add Configuration (Optional)

Create `config/initializers/recording_studio_moveable.rb`:

```ruby
RecordingStudioMoveable.configure do |config|
  config.api_key = ENV["RECORDING_STUDIO_MOVEABLE_API_KEY"]
  config.enable_feature_x = true
  config.timeout = 10
end

RecordingStudio::Moveable.configure do |config|
  config.default_redirect_mode = :moved_record
end
```

Use `redirect_mode` on move links when you need per-request behavior, for example `redirect_mode: "destination"` to land on the folder that received the moved item.

If you are not using built-in authorization, disable it and provide your own `authorization_hook` in the same initializer.
The hook must allow the source and each descendant before a subtree move is persisted.
Metadata submitted through the public move UI is namespaced under `client_metadata`; treat those values as untrusted request input.

### Configure Tailwind (If Using)

Add to your `app/assets/tailwind/application.css`:

```css
@source "../../vendor/bundle/**/recording_studio_moveable/app/views/**/*.erb";
```

Then rebuild:

```bash
bin/rails tailwindcss:build
```

---

## Verifying Installation

1. Start your Rails server:
   ```bash
   bin/rails server
   ```

2. Visit the engine:
   ```
   http://localhost:3000/recording_studio_moveable
   ```

You should see the engine's welcome page.

If built-in authorization is enabled, also verify that an actor with edit access can open the move UI and that an actor without edit access is denied. Those checks should flow through Accessible, even when Accessible is running in compatibility mode on top of `recording_studio` access tables.

---

## Customizing the Mount Path

Change the mount path in `config/routes.rb`:

```ruby
# Mount at root
mount RecordingStudioMoveable::Engine, at: "/"

# Mount at a custom path
mount RecordingStudioMoveable::Engine, at: "/my-engine"

# Mount with constraints
mount RecordingStudioMoveable::Engine, at: "/recording_studio_moveable", constraints: { subdomain: "api" }
```

---

## Accessing Engine Routes

From your host app views:

```erb
<%= link_to "Visit Engine", recording_studio_moveable.root_path %>
```

From controllers:

```ruby
redirect_to recording_studio_moveable.root_path
```

The `recording_studio_moveable` helper provides access to all engine routes.

---

## Overriding Engine Views

To customize engine views, copy them to your app:

```bash
mkdir -p app/views/recording_studio_moveable/home
cp $(bundle show recording_studio_moveable)/app/views/recording_studio_moveable/home/index.html.erb \
   app/views/recording_studio_moveable/home/
```

Rails will use your app's version instead of the engine's.

---

## Overriding Engine Controllers

Create a decorator or subclass:

```ruby
# app/controllers/recording_studio_moveable/home_controller.rb
class RecordingStudioMoveable::HomeController < RecordingStudioMoveable::ApplicationController
  def index
    # Your custom logic
    super
  end
end
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Route not found | Ensure engine is mounted in `config/routes.rb`. |
| Styles missing | Run `bin/rails tailwindcss:build` after adding `@source`. |
| Generator fails | Check that the gem is installed: `bundle show recording_studio_moveable`. |
| Configuration not applied | Ensure initializer runs after engine loads. |

---

## Uninstalling

1. Remove the mount line from `config/routes.rb`
2. Delete `config/initializers/recording_studio_moveable.rb`
3. Remove the gem from `Gemfile`
4. Run `bundle install`
5. Remove the `@source` line from your Tailwind config

---

## Related Documentation

- [Configuration Guide](CONFIGURATION.md) – All configuration options
- [Tailwind Setup](TAILWIND.md) – How Tailwind is configured in the engine

---

Happy integrating! 🔌
