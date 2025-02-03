class AddExcerptToPost < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :excerpt, :text
  end
end
