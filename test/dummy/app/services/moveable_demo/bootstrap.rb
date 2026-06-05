# frozen_string_literal: true

module MoveableDemo
  class Bootstrap
    WORKSPACES = [
      {
        name: "Studio Workspace",
        grant_access: true,
        folders: [
          {
            name: "Songwriting",
            pages: [
              [ "Lyric Draft", "Scratch lyrics and chorus ideas." ],
              [ "Demo Arrangement", "Working notes for the demo arrangement." ],
              [ "Vocal References", "Reference recordings for the vocalist." ]
            ]
          },
          {
            name: "Tracking",
            pages: [
              [ "Mic Locker", "Session microphone choices and placements." ],
              [ "Session Checklist", "Pre-flight tracking checklist." ],
              [ "Drum Notes", "Tuning and room configuration notes." ]
            ]
          },
          {
            name: "Mix Prep",
            pages: [
              [ "Stem Deliverables", "Expected exports for mix handoff." ],
              [ "Recall Notes", "Outboard settings for the next recall." ],
              [ "Client Feedback", "Consolidated revision feedback." ]
            ]
          }
        ],
        archive_boxes: [ "Archive Box A", "Archive Box B" ]
      },
      {
        name: "Client Workspace",
        grant_access: true,
        folders: [
          {
            name: "Incoming",
            pages: [
              [ "Review Queue", "Items waiting for the next client review." ],
              [ "Reference Pulls", "Reference notes shared by the client." ]
            ]
          },
          {
            name: "Approved",
            pages: [
              [ "Ready For Delivery", "Approved files ready for handoff." ],
              [ "Release Notes", "Final release notes for the client workspace." ]
            ]
          }
        ],
        archive_boxes: [ "Client Archive" ]
      },
      {
        name: "Restricted Workspace",
        grant_access: false,
        folders: [
          {
            name: "Executive Notes",
            pages: [
              [ "Hidden Roadmap", "Restricted roadmap notes for internal review." ],
              [ "Budget Draft", "Confidential budget draft for the restricted workspace." ]
            ]
          }
        ],
        archive_boxes: [ "Restricted Archive" ]
      }
    ].freeze

    def self.call(actor:)
      new(actor:).call
    end

    def initialize(actor:)
      @actor = actor
    end

    def call
      raise ArgumentError, "actor is required" if actor.blank?

      ActiveRecord::Base.transaction do
        WORKSPACES.map do |workspace_data|
          workspace = Workspace.find_or_create_by!(name: workspace_data[:name])
          root_recording = ensure_root_recording!(workspace)

          ensure_root_access!(root_recording) if workspace_data[:grant_access]
          ensure_demo_tree!(root_recording, workspace_data)

          root_recording
        end.find { |root_recording| accessible_workspace?(root_recording.recordable.name) }
      end
    end

    private

    attr_reader :actor

    def ensure_root_recording!(workspace)
      RecordingStudio.root_recording_for(workspace)
    end

    def ensure_root_access!(root_recording)
      RecordingStudioAccessible.grant_access(
        recording: root_recording,
        actor: actor,
        role: :admin,
        manager_actor: actor
      )
    end

    def ensure_demo_tree!(root_recording, workspace_data)
      workspace_data[:folders].each do |folder_data|
        folder = RecordingStudioFolder.find_or_create_by!(name: folder_data[:name])
        folder_recording = ensure_recording!(root: root_recording, parent: root_recording, recordable: folder)

        folder_data[:pages].each do |title, body|
          page = RecordingStudioPage.find_or_create_by!(title: title) do |record|
            record.body = body
          end

          if page.body.blank? && body.present?
            page.update!(body: body)
          end

          ensure_recording!(root: root_recording, parent: folder_recording, recordable: page)
        end
      end

      Array(workspace_data[:archive_boxes]).each do |name|
        archive_box = RecordingStudioArchiveBox.find_or_create_by!(name: name)
        ensure_recording!(root: root_recording, parent: root_recording, recordable: archive_box)
      end
    end

    def ensure_recording!(root:, parent:, recordable:)
      existing = RecordingStudio::Recording.unscoped.find_by(
        root_recording_id: root.id,
        recordable: recordable
      )
      return existing if existing

      RecordingStudio.assert_parent_allowed!(child_type: recordable.class.name, parent_recording: parent)

      RecordingStudio::Recording.unscoped.create!(
        root_recording: root,
        parent_recording: parent,
        recordable: recordable
      )
    end

    def accessible_workspace?(workspace_name)
      workspace_data = WORKSPACES.find { |data| data[:name] == workspace_name }
      workspace_data.present? && workspace_data[:grant_access]
    end
  end
end
