class RemoveActionTextRichTexts < ActiveRecord::Migration[8.0]
  def change
    drop_table :action_text_rich_texts
  end
end
