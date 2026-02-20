class AddFeedbackToMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :messages, :feedback, :integer
  end
end
