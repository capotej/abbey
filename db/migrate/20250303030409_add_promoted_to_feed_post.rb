class AddPromotedToFeedPost < ActiveRecord::Migration[8.0]
  def change
    add_column :feed_posts, :promoted, :boolean
  end
end
