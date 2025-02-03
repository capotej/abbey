class TaggingIndexUnique < ActiveRecord::Migration[8.0]
  def change
    remove_index :taggings, [ :post_id, :tag_id ]
    add_index :taggings, [ :post_id, :tag_id ], unique: true
  end
end
