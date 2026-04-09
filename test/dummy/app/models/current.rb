class Current < ActiveSupport::CurrentAttributes
  attribute :actor, :impersonator, :root_recording, :workspace
end
