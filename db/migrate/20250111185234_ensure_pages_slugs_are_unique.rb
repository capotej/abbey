class EnsurePagesSlugsAreUnique < ActiveRecord::Migration[8.0]
  def change
    remove_index :pages, :slug
    add_index :pages, :slug, unique: true
  end
end
