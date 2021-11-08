class CreateGachas < ActiveRecord::Migration[6.1]
  def self.up
    create_table :gachas do |t|
      t.integer :user_id
      t.string :title
      t.string :result
      t.timestamps null: false
    end
  end

  def self.down
    drop_table :gachas
  end
end
