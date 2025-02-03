class CreateLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :links do |t|
      t.string :url
      t.string :title
      t.string :description

      t.timestamps
    end
    add_index :links, :url, unique: true
  end
end
