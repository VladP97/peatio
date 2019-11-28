class AddStatusToMessages < ActiveRecord::Migration[5.2]
  def change
    add_column :messages, :status, :integer, default: 0, null: false
  end
end
