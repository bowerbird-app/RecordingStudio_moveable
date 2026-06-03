# frozen_string_literal: true

require "test_helper"
require "action_controller"

class MoveablesControllerMetadataTest < Minitest::Test
  def test_request_metadata_is_namespaced_as_client_metadata
    controller = RecordingStudioMoveable::MoveablesController.new
    params = ActionController::Parameters.new(
      metadata: {
        reason: "reorg",
        authorization_context: "forged"
      }
    )

    controller.define_singleton_method(:params) { params }

    assert_equal(
      {
        "client_metadata" => {
          "reason" => "reorg",
          "authorization_context" => "forged"
        }
      },
      controller.send(:move_metadata)
    )
  end
end
