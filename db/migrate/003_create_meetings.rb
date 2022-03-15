class CreateMeetings < ActiveRecord::Migration[6.1]
  def self.up
    create_table :meetings do |t|
      t.string :name
      t.string :meeting_id
      t.timestamps null: false
    end

    add_column :gachas, :meeting_id, :integer
  end

  def self.down
    drop_table :meetings
    remove_column :gachas, :meeting_id
  end
end
