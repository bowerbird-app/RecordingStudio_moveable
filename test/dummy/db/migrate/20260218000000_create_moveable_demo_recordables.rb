class CreateMoveableDemoRecordables < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_folders, id: :uuid do |t|
      t.string :name, null: false
      t.timestamps
    end

    create_table :recording_studio_pages, id: :uuid do |t|
      t.string :title, null: false
      t.text :body
      t.timestamps
    end

    create_table :recording_studio_archive_boxes, id: :uuid do |t|
      t.string :name, null: false
      t.timestamps
    end
  end
end
