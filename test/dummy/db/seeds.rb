# frozen_string_literal: true

# Idempotent seed command:
#   bin/rails db:seed
# Optional hard reset:
#   bin/rails db:drop db:create db:migrate db:seed

user = User.find_or_create_by!(email: "admin@admin.com") do |u|
  u.password = "Password"
  u.password_confirmation = "Password"
end

Current.actor = user
root_access = RecordingStudio::Access.find_or_initialize_by(actor: user)
root_access.role = :admin
root_access.save! if root_access.new_record? || root_access.changed?

WORKSPACES = [
  {
    name: "Studio Workspace",
    grant_access: true,
    folders: Array.new(12) { |index| { name: "Team Folder #{index + 1}", page_count: 5 } },
    archive_boxes: [ "Archive Box 1", "Archive Box 2", "Archive Box 3" ]
  },
  {
    name: "Client Workspace",
    grant_access: true,
    folders: [
      { name: "Incoming", page_count: 3 },
      { name: "Approved", page_count: 3 },
      { name: "Delivered", page_count: 2 }
    ],
    archive_boxes: [ "Client Archive" ]
  },
  {
    name: "Restricted Workspace",
    grant_access: false,
    folders: [
      { name: "Executive Notes", page_count: 2 },
      { name: "Confidential Delivery", page_count: 1 }
    ],
    archive_boxes: [ "Restricted Archive" ]
  }
].freeze

def ensure_recording(root:, parent:, recordable:, actor:)
  existing = RecordingStudio::Recording.unscoped.find_by(
    root_recording_id: root.id,
    parent_recording_id: parent.id,
    recordable: recordable
  )
  return existing if existing

  root.record(recordable, actor: actor, parent_recording: parent)
end

seeded_roots = WORKSPACES.map do |workspace_data|
  workspace = Workspace.find_or_create_by!(name: workspace_data[:name])
  root_recording = RecordingStudio::Recording.unscoped.find_or_create_by!(
    recordable: workspace,
    parent_recording_id: nil
  )

  if workspace_data[:grant_access]
    RecordingStudio::Recording.unscoped.find_or_create_by!(
      root_recording_id: root_recording.id,
      parent_recording_id: root_recording.id,
      recordable: root_access
    )
  end

  folder_recordings = workspace_data[:folders].map do |folder_data|
    folder = RecordingStudioFolder.find_or_create_by!(name: folder_data[:name])
    ensure_recording(root: root_recording, parent: root_recording, recordable: folder, actor: user)
  end

  folder_recordings.each_with_index do |folder_recording, folder_index|
    page_count = workspace_data[:folders][folder_index][:page_count]

    page_count.times do |index|
      page = RecordingStudioPage.find_or_create_by!(title: "#{workspace_data[:name]} Folder #{folder_index + 1} Page #{index + 1}") do |p|
        p.body = "Seeded page #{index + 1} inside #{workspace_data[:folders][folder_index][:name]}."
      end

      ensure_recording(root: root_recording, parent: folder_recording, recordable: page, actor: user)
    end
  end

  Array(workspace_data[:archive_boxes]).each do |archive_name|
    archive_box = RecordingStudioArchiveBox.find_or_create_by!(name: archive_name)
    ensure_recording(root: root_recording, parent: root_recording, recordable: archive_box, actor: user)
  end

  root_recording
end

puts "Seeded: admin@admin.com / Password"
puts "Seeded: Workspaces #{seeded_roots.map { |root| root.recordable.name }.join(', ')}"
puts "Seeded: #{RecordingStudioFolder.count} folders, #{RecordingStudioPage.count} pages, #{RecordingStudioArchiveBox.count} archive boxes"
