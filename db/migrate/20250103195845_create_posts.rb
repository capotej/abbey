class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.boolean :draft
      t.text :content
      t.string :title

      t.timestamps
    end
  end
end
