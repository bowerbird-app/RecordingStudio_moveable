> **Architecture Documentation**
> *   **Canonical Source:** [bowerbird-app/RecordingStudio_moveable](https://github.com/bowerbird-app/RecordingStudio_moveable/tree/main/docs/recording_studio_moveable)
> *   **Last Updated:** July 29, 2026
>
> *Maintainers: Please update the date above when modifying this file.*

---

# Optional RecordingStudio API Action

`recording_studio_moveable` works without `recording_studio_api`. When the host application installs
`RecordingStudioApi`, Moveable registers a member `move` action for the `:movable` capability during engine
initialization. The action is registered before RecordingStudioApi's fallback action, so the handler remains
owned by this addon.

The action contract is version `1.0.0`, uses `POST`, requires `:edit`, and is automatically exposed only for
recordable types that enable `:movable`.

## Install the Optional API Engine

Add the API and its browser-administration dependency to the **host application's** `Gemfile`. They are
intentionally not dependencies of this gem.

```ruby
gem "recording_studio_api", github: "bowerbird-app/RecordingStudio_api", tag: "0.1.0"
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
```

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
