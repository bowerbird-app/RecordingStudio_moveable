# Migration Notes - RecordingStudio 3 Compatibility

## Changes Made

1. ✅ Updated `recording_studio` to `~> 3.0` and RecordingStudio tag `recording_studio/v3.0.0`.
2. ✅ Updated `recording_studio_accessible` to `~> 0.3` and tag `0.3.1`.
3. ✅ Kept `recording_studio_root_switchable` out of the runtime dependency set.
4. ✅ Replaced legacy Accessible child setup with `RecordingStudio.enable_capability(:accessible, on: self)` on root recordables.
5. ✅ Updated dummy app access grants to use `RecordingStudioAccessible.grant_access`.
6. ✅ Preserved RecordingStudio core hierarchy declarations through `recording_studio_recordable allowed_parent_types:`.
7. ✅ Updated README and generated documentation for RecordingStudio 3 / Accessible 0.3 setup.

## Host Application Migration Steps

Applications upgrading to this compatibility release should:

1. **Update dependencies**:
   ```bash
   bundle install
   ```

2. **Install or verify Accessible setup**:
   ```bash
   bin/rails generate recording_studio_accessible:install
   bin/rails generate recording_studio_accessible:migrations
   bin/rails db:migrate
   ```

3. **Enable Accessible on root recordables** with `RecordingStudio.enable_capability(:accessible, on: self)`.

4. **Declare hierarchy rules in RecordingStudio core** using `recording_studio_recordable allowed_parent_types:`.

5. **Run tests**:
   ```bash
   bundle exec rake test
   bundle exec rake app:test
   ```

## Breaking Change and Release Classification

This update drops compatibility with RecordingStudio 2.x. The expected release classification is **major**, and merge metadata should preserve a Conventional Commits breaking-change signal.
