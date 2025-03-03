class CreateFeedPosts < ActiveRecord::Migration[8.0]
  def change
    create_table :feed_posts do |t|
      t.string :guid
      t.string :summary
      t.string :url
      t.string :title
      t.integer :feed_id

      t.timestamps
    end
    add_index :feed_posts, :guid, unique: true
  end
end
