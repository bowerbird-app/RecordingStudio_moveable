> **Architecture Documentation**
> *   **Canonical Source:** [bowerbird-app/RecordingStudio_moveable](https://github.com/bowerbird-app/RecordingStudio_moveable/tree/main/docs/recording_studio_moveable)
> *   **Last Updated:** August 21, 2026
>
> *Maintainers: Please update the date above when modifying this file.*

---

# Optional RecordingStudio API Action

`recording_studio_moveable` works without `recording_studio_api`. When the host application installs
`RecordingStudioApi`, Moveable registers a member `move` action for the `:movable` capability during engine
initialization. Current RecordingStudio API releases still require RecordingStudio `~> 3.0`, so this optional
integration is deferred until that gem declares RecordingStudio 4 support. Keep the adapter in host apps that
already have a compatible API engine.

The action contract is version `1.0.0`, uses `POST`, and requires `:edit`. A surface exposes it only when the
recordable type enables `:movable` **and** that API surface's recordable-type registration explicitly allowlists
`:move`.

## Enable Moveable on Source Types

Each recordable type that should be movable through the API must declare its structural parent types and include
the Moveable capability. The API action is available only for these source types:

```ruby
class RecordingStudioPage < ApplicationRecord
  recording_studio_recordable(
    label: "Page",
    root: false,
    allowed_parent_types: ["Workspace", "RecordingStudioFolder"]
  )

  include RecordingStudio::Capabilities::Moveable.to
end
```

Pass `allow_cross_root: true` to `.to` only when the recordable may move between roots. A request must still
target an accessible, editable destination whose type is listed in `allowed_parent_types`.

## Install the Optional API Engine

Add the API and its browser-administration dependency to the **host application's** `Gemfile`. They are
intentionally not dependencies of this gem.

```ruby
gem "recording_studio_api", github: "bowerbird-app/RecordingStudio_api", tag: "0.2.0"
gem "recording_studio_admin", github: "bowerbird-app/RecordingStudio_admin", tag: "1.1.0"
```

Then run the API generators from the host application directory:

```bash
bin/rails generate recording_studio_api:install
bin/rails generate recording_studio_api:migrations
bin/rails db:migrate
```

The install generator mounts `RecordingStudioApi::Engine`, creates its initializer, and configures Tailwind when
applicable. The migrations generator copies the API engine migrations into the host application.

RecordingStudio API 0.2.0 provides gem-owned Scalar documentation. Install a named reference instead of copying
or maintaining Scalar controllers and views in the host application:

```bash
bin/rails generate recording_studio_api:scalar_docs moveable_api \
  --mount-path=/recording_studio_api/docs/scalar \
  --api-mount-path=/recording_studio_api \
  --api-surface=public \
  --access=authenticated \
  --layout=recording_studio/default_layout
```

This adds managed routes and configuration while keeping the OpenAPI endpoint and Scalar assets in the API gem.
Enable both `:accessible` and `:api_access_point` on each root recordable type that may receive API access:

```ruby
RecordingStudio.enable_capability(:accessible, on: Workspace)
RecordingStudio.enable_capability(:api_access_point, on: Workspace)
```

## Configure an API Version Profile

Without a version profile, RecordingStudioApi selects the current `move` action automatically. A host that
publishes version profiles should explicitly select the Moveable contract:

```ruby
# config/initializers/recording_studio_api.rb
RecordingStudioApi.configure do |config|
  config.api_versions = %w[v1]
  config.default_api_version = "v1"

  config.version "v1" do |api|
    api.use :moveable, "~> 1.0"
  end
end

RecordingStudioApi.register_recordable_type_api(
  "RecordingStudioFolder",
  capability_actions: %i[move]
)
RecordingStudioApi.register_recordable_type_api(
  "RecordingStudioPage",
  capability_actions: %i[move]
)
```

RecordingStudio API 0.2.0 uses a default-deny allowlist for custom capability actions. Register `:move` only for
the recordable types that should publish Moveable's action. The underlying `:movable` capability and the API
authorization checks are still required.

Named APIs have independent action and recordable-type registries. Configure the named surface and allowlist
`:move` on that surface explicitly:

```ruby
RecordingStudioApi.configure do |config|
  config.api :operations do |api|
    api.api_versions = %w[v1]
    api.default_api_version = "v1"

    api.version "v1" do |version|
      version.use :moveable, "~> 1.0"
    end
  end
end

RecordingStudioApi.register_recordable_type_api(
  "RecordingStudioPage",
  api: :operations,
  capability_actions: %i[move]
)
```

This named allowlist does not expose `:move` on `public`, and the public allowlist does not expose it on
`:operations`.

## Endpoint and Input

For a moveable `RecordingStudioPage`, clients call:

```http
POST /recording_studio_api/api/v1/recording_studio_pages/:id/actions/move
Content-Type: application/json
Authorization: ******

{ "parent_id": "<destination-recording-id>" }
```

`parent_id` is preferred. `destination_id` and `new_parent_id` are supported aliases for existing clients.
All other input keys are rejected. The handler limits destination lookup to the API access grant's accessible
recordings and authorizes `:edit` access to both the source and destination before calling `move_to!`. It records
the API action, API client ID, and credential ID as move metadata and returns the reloaded recording for API
serialization.

Structural move failures, including self/descendant destinations, invalid parent types, and prohibited
cross-root moves, return `422 Unprocessable Entity`. Move policy denials return `403 Forbidden`.

RecordingStudioApi also supports the compatibility alias:

```text
POST /recording_studio_api/api/v1/recording_studio_pages/:id/move
```

## Related API Documentation

- [Capability-backed actions](https://github.com/bowerbird-app/RecordingStudio_api#capability-backed-actions)
- [Versioning model](https://github.com/bowerbird-app/RecordingStudio_api#versioning-model)
- [API endpoints](https://github.com/bowerbird-app/RecordingStudio_api#api-endpoints)
