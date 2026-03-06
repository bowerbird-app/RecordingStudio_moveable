# frozen_string_literal: true

module MoveableDemo
  class Bootstrap
    FOLDERS = [
      {
        name: "Songwriting",
        pages: [
          ["Lyric Draft", "Scratch lyrics and chorus ideas."],
          ["Demo Arrangement", "Working notes for the demo arrangement."],
          ["Vocal References", "Reference recordings for the vocalist."]
        ]
      },
      {
        name: "Tracking",
        pages: [
          ["Mic Locker", "Session microphone choices and placements."],
          ["Session Checklist", "Pre-flight tracking checklist."],
          ["Drum Notes", "Tuning and room configuration notes."]
        ]
      },
      {
        name: "Mix Prep",
        pages: [
          ["Stem Deliverables", "Expected exports for mix handoff."],
          ["Recall Notes", "Outboard settings for the next recall."],
          ["Client Feedback", "Consolidated revision feedback."]
        ]
      }
    ].freeze

    ARCHIVE_BOXES = [
      "Archive Box A",
      "Archive Box B"
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
        workspace = Workspace.find_or_create_by!(name: "Studio Workspace")
        root_recording = ensure_root_recording!(workspace)

        ensure_root_access!(root_recording)
        ensure_demo_tree!(root_recording)

        root_recording
      end
    end

    private

    attr_reader :actor

    def ensure_root_recording!(workspace)
      RecordingStudio::Recording.unscoped.find_or_create_by!(
        recordable: workspace,
        parent_recording_id: nil
      )
    end

    def ensure_root_access!(root_recording)
      access = RecordingStudio::Access.find_by(actor: actor)

      if access.present?
        access.update!(role: :admin) if access.role.to_sym != :admin
        return RecordingStudio::Recording.unscoped.find_or_create_by!(
          root_recording_id: root_recording.id,
          parent_recording_id: root_recording.id,
          recordable: access
        )
      end

      root_recording.record(RecordingStudio::Access, actor: actor, parent_recording: root_recording) do |new_access|
        new_access.actor = actor
        new_access.role = :admin
      end
    end

    def ensure_demo_tree!(root_recording)
      FOLDERS.each do |folder_data|
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

      ARCHIVE_BOXES.each do |name|
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

      RecordingStudio::Recording.unscoped.create!(
        root_recording_id: root.id,
        parent_recording_id: parent.id,
        recordable: recordable
      )
    end
  end
end