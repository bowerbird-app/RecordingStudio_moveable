class DataController < ApplicationController
  def index
    @data_sections = [
      {
        title: "Workspaces",
        records: workspace_rows,
        columns: [
          { title: "Name", key: :name },
          { title: "Access", key: :access }
        ]
      },
      {
        title: "Folders",
        records: folder_rows,
        columns: [
          { title: "Name", key: :name },
          { title: "Parent", key: :parent }
        ]
      },
      {
        title: "Pages",
        records: page_rows,
        columns: [
          { title: "Name", key: :name },
          { title: "Parent", key: :parent }
        ]
      },
      {
        title: "Users",
        records: User.order(:email).pluck(:email)
      },
      {
        title: "Archive Boxes",
        records: RecordingStudioArchiveBox.order(:name).pluck(:name)
      }
    ]
  end

  private

  def workspace_rows
    RecordingStudio::Recording.unscoped
      .where(recordable_type: "Workspace", parent_recording_id: nil)
      .includes(:recordable)
      .sort_by { |root_recording| root_recording.recordable.name.downcase }
      .map do |root_recording|
        {
          name: root_recording.recordable.name,
          access: workspace_access_emails(root_recording).presence || "No users"
        }
      end
  end

  def workspace_access_emails(root_recording)
    RecordingStudioAccessible.access_recordings_for(root_recording)
      .filter_map { |access_recording| access_recording.recordable.actor&.email }
      .sort
      .join(", ")
  end

  def folder_rows
    RecordingStudio::Recording.unscoped
      .where(recordable_type: "RecordingStudioFolder")
      .includes(:recordable, parent_recording: :recordable)
      .sort_by { |folder_recording| folder_recording.recordable.name.downcase }
      .map do |folder_recording|
        {
          name: folder_recording.recordable.name,
          parent: parent_label(folder_recording.parent_recording)
        }
      end
  end

  def page_rows
    RecordingStudio::Recording.unscoped
      .where(recordable_type: "RecordingStudioPage")
      .includes(:recordable, parent_recording: :recordable)
      .sort_by { |page_recording| page_recording.recordable.title.downcase }
      .map do |page_recording|
        {
          name: page_recording.recordable.title,
          parent: parent_label(page_recording.parent_recording)
        }
      end
  end

  def parent_label(parent_recording)
    return "None" if parent_recording.blank?

    recordable = parent_recording.recordable
    if recordable.respond_to?(:name) && recordable.name.present?
      recordable.name
    elsif recordable.respond_to?(:title) && recordable.title.present?
      recordable.title
    else
      recordable.class.name.demodulize
    end
  end
end
