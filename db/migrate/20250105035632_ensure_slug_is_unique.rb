class EnsureSlugIsUnique < ActiveRecord::Migration[8.0]
  def change
    remove_index :posts, :slug
    add_index :posts, :slug, unique: true
  end
end
