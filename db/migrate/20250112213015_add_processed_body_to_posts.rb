class AddProcessedBodyToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :processed_body, :text
    add_column :posts, :processed_excerpt, :text
  end
end
