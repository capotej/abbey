class TaggingIndex < ActiveRecord::Migration[8.0]
  def change
    add_index :taggings, [ :post_id, :tag_id ]
  end
end
