class CreatePapers < ActiveRecord::Migration[8.0]
  def change
    create_table :papers do |t|
      t.string :title
      t.text :description
      t.string :url

      t.timestamps
    end

    add_index :papers, :url, unique: true
  end
end
