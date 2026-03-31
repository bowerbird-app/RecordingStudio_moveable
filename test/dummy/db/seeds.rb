# frozen_string_literal: true

# Idempotent seed command:
#   bin/rails db:seed
# Optional hard reset:
#   bin/rails db:drop db:create db:migrate db:seed

user = User.find_or_create_by!(email: "admin@admin.com") do |u|
  u.password = "Password"
  u.password_confirmation = "Password"
end

workspace = Workspace.find_or_create_by!(name: "Studio Workspace")
root_recording = RecordingStudio::Recording.unscoped.find_or_create_by!(
  recordable: workspace,
  parent_recording_id: nil
)

Current.actor = user
root_access = RecordingStudio::Access.find_or_initialize_by(actor: user)
root_access.role = :admin
root_access.save! if root_access.new_record? || root_access.changed?
RecordingStudio::Recording.unscoped.find_or_create_by!(
  root_recording_id: root_recording.id,
  parent_recording_id: root_recording.id,
  recordable: root_access
)

def ensure_recording(root:, parent:, recordable:, actor:)
  existing = RecordingStudio::Recording.unscoped.find_by(
    root_recording_id: root.id,
    parent_recording_id: parent.id,
    recordable: recordable
  )
  return existing if existing

  root.record(recordable, actor: actor, parent_recording: parent)
end

primary_folders = []
12.times do |index|
  folder = RecordingStudioFolder.find_or_create_by!(name: "Team Folder #{index + 1}")
  primary_folders << ensure_recording(root: root_recording, parent: root_recording, recordable: folder, actor: user)
end

primary_folders.each_with_index do |folder_recording, folder_index|
  5.times do |index|
    page = RecordingStudioPage.find_or_create_by!(title: "Folder #{folder_index + 1} Page #{index + 1}") do |p|
      p.body = "Seeded page #{index + 1} inside folder #{folder_index + 1}."
    end

    ensure_recording(root: root_recording, parent: folder_recording, recordable: page, actor: user)
  end
end

3.times do |index|
  archive_box = RecordingStudioArchiveBox.find_or_create_by!(name: "Archive Box #{index + 1}")
  ensure_recording(root: root_recording, parent: root_recording, recordable: archive_box, actor: user)
end

puts "Seeded: admin@admin.com / Password"
puts "Seeded: Workspace '#{workspace.name}' with root recording ##{root_recording.id}"
puts "Seeded: #{RecordingStudioFolder.count} folders, #{RecordingStudioPage.count} pages, #{RecordingStudioArchiveBox.count} archive boxes"
