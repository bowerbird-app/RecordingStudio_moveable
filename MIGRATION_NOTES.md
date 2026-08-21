# Migration Notes - RecordingStudio 4.2 Compatibility

## Changes Made

1. ✅ Updated `recording_studio` to `~> 4.2` and RecordingStudio tag `v4.2.0`.
2. ✅ Updated `recording_studio_accessible` to `~> 0.6` and tag `v0.6.0`.
3. ✅ Converted the host verb to keyword-only `Moveable.to(allow_cross_root: ...)`, wrapping `RecordingStudio::Capabilities.include_for(:movable, **options)`.
4. ✅ Kept `register_capability` at boot. Installing the gem does not enable `:movable`.
5. ✅ Kept positional destination `.to` raising `DESTINATION_API_REMOVED_MESSAGE`. `.enabled` aliases `.to`.
6. ✅ Defaulted full-page move screens to `recording_studio/default_layout`.
7. ✅ Deferred dummy RecordingStudio API integration until that gem supports RecordingStudio 4.

## Host Application Migration Steps

Applications upgrading to this compatibility release should:

1. **Update dependencies**:
   ```bash
   bundle install
   ```

2. **Install RecordingStudio 4 migrations**:
   ```bash
   bin/rails generate recording_studio:migrations
   bin/rails db:migrate
   ```

3. **Configure Accessible actor types** before creating new grants:
   ```ruby
   RecordingStudioAccessible.configure do |config|
     config.access_actor_types = ["User"]
   end
   ```

4. **Switch the host verb** to keyword-only `.to`:
   ```ruby
   include RecordingStudio::Capabilities::Moveable.to(allow_cross_root: true)
   ```

5. **Run tests**:
   ```bash
   bundle exec rake test
   bundle exec rake app:test
   ```

## Breaking Change and Release Classification

This update drops compatibility with RecordingStudio 3.x. The expected release classification is **major**.
