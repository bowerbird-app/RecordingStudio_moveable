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
seeded_root = MoveableDemo::Bootstrap.call(actor: user)

puts "Seeded: admin@admin.com / Password"
puts "Seeded: Default workspace #{seeded_root.recordable.name}"
puts "Seeded: Workspaces #{Workspace.order(:name).pluck(:name).join(', ')}"
puts "Seeded: #{RecordingStudioFolder.count} folders, #{RecordingStudioPage.count} pages, #{RecordingStudioArchiveBox.count} archive boxes"
