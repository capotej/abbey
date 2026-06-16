class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.integer :year
      t.string :github_url
      t.string :license
      t.string :language
      t.text :description

      t.timestamps
    end
  end
end
