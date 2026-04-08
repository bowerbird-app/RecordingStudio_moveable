# frozen_string_literal: true

# Example migration for RecordingStudioMoveable.
#
# This migration creates a sample table to demonstrate the migration generator.
# Replace or remove this migration with your actual engine tables.

class CreateRecordingStudioMoveableExamples < ActiveRecord::Migration[7.1]
  def change
    create_table :recording_studio_moveable_examples, id: :uuid do |t|
      t.string :name, null: false
      t.text :description
      t.jsonb :metadata, default: {}
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :recording_studio_moveable_examples, :name
    add_index :recording_studio_moveable_examples, :active
  end
end
