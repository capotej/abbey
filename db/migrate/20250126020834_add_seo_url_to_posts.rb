class AddSeoUrlToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :redirect_from, :string
    add_index :posts, :redirect_from, unique: true
  end
end
