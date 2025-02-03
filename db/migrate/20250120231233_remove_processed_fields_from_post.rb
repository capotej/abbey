class RemoveProcessedFieldsFromPost < ActiveRecord::Migration[8.0]
  def change
    remove_column :posts, :processed_body, :processed_excerpts
    rename_column :posts, :excerpt, :markdown_excerpt
  end
end
