# Hooks

Moveable 6.0 does not ship `RecordingStudioMoveable::Hooks`. `RecordingStudioMoveable.configuration.hooks` is gone. `configuration.to_h` no longer includes `:hooks_registered`.

Register hooks on Core.

```ruby
RecordingStudio.configure do |config|
  config.hooks.after_record do |event|
    next unless event.action == "moved"

    # Host work for a completed move.
  end
end
```

`RecordingStudio::Hooks.run` and `RecordingStudio::Hooks.trigger` run hooks on `RecordingStudio.configuration.hooks`.

Moveable's engine no longer runs `before_initialize`, `on_configuration`, `after_initialize`, `active_record_loaded`, or `action_controller_loaded`.

`move_to!` still appends a `moved` event through Core. `before_record` and `after_record` on `RecordingStudio.configuration.hooks` see that write.

The optional API move action extends the API controller through `RecordingStudioApi.configuration.hooks`. That registry belongs to the API gem.
