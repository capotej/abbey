class RemoveProcessedFieldsFromPostForgotOne < ActiveRecord::Migration[8.0]
  def change
    remove_column :posts, :processed_excerpt
  end
end
