class AddFeed < ActiveRecord::Migration[8.0]
  def change
    create_table :feeds do |t|
      t.string :name, null: false
      t.string :url, null: false

      t.timestamps
    end
    add_index :feeds, [ :name, :url ], unique: true
  end
end
