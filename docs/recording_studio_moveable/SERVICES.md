# Services

Moveable 6.0 does not ship a service base. `RecordingStudioMoveable::Services::BaseService` and `RecordingStudioMoveable::Services::ExampleService` are gone.

A host service inherits `RecordingStudio::Services::BaseService`. Implement `perform`, and return `success` or `failure`. Call the service with `.call`. The result is `RecordingStudio::Services::BaseService::Result`.

```ruby
class NotifyMove < RecordingStudio::Services::BaseService
  def initialize(recording:)
    super()
    @recording = recording
  end

  private

  def perform
    return failure("Recording is required") if @recording.nil?

    success(@recording)
  end
end

result = NotifyMove.call(recording: recording)
result.value if result.success?
```

Moveable's own move path is `Recording#move_to!` on the move capability. That method does not go through a service object.
