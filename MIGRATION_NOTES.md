# Migration Notes - RecordingStudio 4 Compatibility

## Changes Made

1. Updated `recording_studio` to `~> 4.0` and RecordingStudio tag `v4.0.0`.
2. Updated `recording_studio_accessible` to `~> 0.6` (Accessible 0.6 release branch until tagged).
3. Kept `recording_studio_root_switchable` out of the runtime dependency set.
4. Installed the RecordingStudio 4 harden / unique-root indexes in the dummy app.
5. Configured Accessible `access_actor_types` in the dummy app.
6. Aligned FlatPack usage with `v0.1.132` (`Sidebar::Item` `text:`, PageNav `secondary_anchor_href`).
7. Deferred dummy RecordingStudio API integration until API declares RecordingStudio 4 support.
8. Updated README, install, upgrade, and API documentation for RecordingStudio 4 / Accessible 0.6.

## Host Application Migration Steps

Applications upgrading to this compatibility release should:

1. **Update dependencies**:
   ```ruby
   gem "recording_studio", "~> 4.0"
   gem "recording_studio_accessible", "~> 0.6"
   gem "recording_studio_moveable", "~> 3.0"
   ```

2. **Install RecordingStudio 4 migrations**:
   ```bash
   bin/rails generate recording_studio:migrations
   bin/rails db:migrate
   ```

3. **Configure Accessible actor types** before granting access:
   ```ruby
   RecordingStudioAccessible.configure do |config|
     config.access_actor_types = ["User"]
   end
   ```

4. **Keep Accessible enabled on root recordables** with `RecordingStudio.enable_capability(:accessible, on: self)`.

5. **Run tests**:
   ```bash
   bundle exec rake test
   bundle exec rake app:test
   ```

## Breaking Change and Release Classification

This update drops compatibility with RecordingStudio 3.x. The expected release classification is **major**.
