class AddDraftIndex < ActiveRecord::Migration[8.0]
  def change
    add_index :posts, :draft
  end
end
