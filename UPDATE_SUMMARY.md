# RecordingStudio Moveable 3.0.0 Release Notes

Released: August 18, 2026

## Summary

`3.0.0` moves `recording_studio_moveable` onto RecordingStudio 4 and Accessible 0.6. The move capability, authorization path, and UI stay the same; hosts must upgrade the Recording Studio stack and run the 4.0 harden migration.

## Breaking Changes

- Require `recording_studio ~> 4.0`.
- Require `recording_studio_accessible ~> 0.6`.
- Drop compatibility with RecordingStudio 3.x and Accessible 0.3–0.5.

## Key Changes

- Development and dummy bundles pin RecordingStudio `v4.0.0`, Accessible `0.6.0`, Admin `1.2.0`, and FlatPack `v0.1.132`.
- Dummy installs the RecordingStudio 4 harden / unique-root indexes and configures `access_actor_types = ["User"]`.
- Moveable prefers RecordingStudio core Labels when present.
- Move screens use FlatPack PageNav `secondary_anchor_href` for return navigation.
- Optional RecordingStudio API remains supported in the gem, but the dummy app defers that engine until API declares RecordingStudio 4 support.

## Upgrade Notes

1. Upgrade hosts to RecordingStudio `~> 4.0` and Accessible `~> 0.6` with this release. Stay on Moveable `2.1.x` while remaining on RecordingStudio 3.
2. Run `bin/rails generate recording_studio:migrations` and `bin/rails db:migrate`.
3. Configure Accessible actor allowlisting before creating new grants:

```ruby
RecordingStudioAccessible.configure do |config|
  config.access_actor_types = ["User"]
end
```

4. Follow RecordingStudio 4.0 upgrade notes for implicit recording order and append-only events.
5. Re-add `recording_studio_api` to host apps only after that gem supports RecordingStudio 4. Moveable still registers its optional move action automatically when the API engine is loaded.
