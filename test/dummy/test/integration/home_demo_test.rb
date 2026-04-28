# frozen_string_literal: true

require_relative "../test_helper"

class HomeDemoTest < ActionDispatch::IntegrationTest
  def setup
    super

    @user = create_user(email: "demo@example.com")
    bootstrap_demo_for(@user)
    sign_in @user
  end

  def test_home_bootstraps_and_renders_demo_tree
    get root_path

    assert_response :success
    assert_includes response.body, "Studio Workspace"
    refute_includes response.body, 'data-icon-name="rectangle-stack"'
    assert_includes response.body, "Songwriting"
    assert_includes response.body, "Folder"
    assert_includes response.body, 'data-icon-name="folder"'
    assert_includes response.body, "Move"
    assert_includes response.body, "Modal"
    refute_includes response.body, "Lyric Draft"
    refute_includes response.body, "Move page"
    refute_includes response.body, "Open folder"
    refute_includes response.body, "Archive Box A"
    refute_includes response.body, "Restricted Workspace"
    assert_includes response.body, 'data-recording-studio-moveable-modal="true"'

    root = RecordingStudio::Recording.unscoped.find_by!(recordable: Workspace.find_by!(name: "Studio Workspace"), parent_recording_id: nil)
    assert_equal 3, RecordingStudio::Recording.where(parent_recording_id: root.id, recordable_type: "RecordingStudioFolder").count
    assert_equal 2, RecordingStudio::Recording.where(parent_recording_id: root.id, recordable_type: "RecordingStudioArchiveBox").count
    assert_equal 9, RecordingStudio::Recording.where(root_recording_id: root.id, recordable_type: "RecordingStudioPage").count
    assert_equal :admin, RecordingStudioAccessible::DirectAccessQuery.access_recordings_for_actor(
      recording: root,
      actor: @user
    ).first.recordable.role.to_sym
  end

  def test_home_bootstrap_does_not_recreate_moved_page_in_original_folder
    get root_path

    root = RecordingStudio::Recording.unscoped.find_by!(recordable: Workspace.find_by!(name: "Studio Workspace"), parent_recording_id: nil)
    lyric_draft = RecordingStudio::Recording.joins("INNER JOIN recording_studio_pages ON recording_studio_pages.id = recording_studio_recordings.recordable_id")
                                           .find_by!(
                                             root_recording_id: root.id,
                                             recordable_type: "RecordingStudioPage",
                                             recording_studio_pages: { title: "Lyric Draft" }
                                           )
    target_folder = RecordingStudio::Recording.joins("INNER JOIN recording_studio_folders ON recording_studio_folders.id = recording_studio_recordings.recordable_id")
                                             .where(root_recording_id: root.id, recordable_type: "RecordingStudioFolder")
                                             .where.not(id: lyric_draft.parent_recording_id)
                                             .find_by!(recording_studio_folders: { name: "Tracking" })

    lyric_draft.move_to!(new_parent: target_folder, actor: @user)

    get root_path

    matches = RecordingStudio::Recording.joins("INNER JOIN recording_studio_pages ON recording_studio_pages.id = recording_studio_recordings.recordable_id")
                                      .where(
                                        root_recording_id: root.id,
                                        recordable_type: "RecordingStudioPage",
                                        recording_studio_pages: { title: "Lyric Draft" }
                                      )

    assert_equal 1, matches.count
    assert_equal target_folder.id, matches.first.parent_recording_id
  end

  def test_folder_page_renders_nested_folders_and_pages_for_selected_folder
    get root_path

    folder = RecordingStudioFolder.find_by!(name: "Songwriting")
    folder_recording = RecordingStudio::Recording.find_by!(recordable: folder)
    folder_recording.root_recording.record(RecordingStudioFolder, actor: @user, parent_recording: folder_recording) do |child_folder|
      child_folder.name = "Chorus Ideas"
    end

    get recording_studio_folder_path(folder)

    assert_response :success
    assert_includes response.body, "All folders"
    assert_includes response.body, "4 items in this folder"
    assert_includes response.body, "Chorus Ideas"
    assert_includes response.body, "Open this folder to browse its nested folders and pages."
    assert_includes response.body, "Lyric Draft"
    assert_includes response.body, "Page"
    assert_includes response.body, 'data-icon-name="document"'
    assert_includes response.body, "Demo Arrangement"
    assert_includes response.body, "Move"
    assert_includes response.body, "Modal"
    refute_includes response.body, "Open page"
    refute_includes response.body, "Move page"
    assert_includes response.body, 'data-recording-studio-moveable-modal="true"'
    refute_includes response.body, "Mic Locker"
  end
end
