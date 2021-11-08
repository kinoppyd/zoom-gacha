class CreateUsers < ActiveRecord::Migration[6.1]
  def self.up
    create_table :users do |t|
      t.string :email
      t.timestamps null: false
    end
  end

  def self.down
    drop_table :users
  end
end
