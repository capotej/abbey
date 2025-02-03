class AddMarkdownBodyToPostsAndPages < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :markdown_body, :text
    add_column :pages, :markdown_body, :text
  end
end
