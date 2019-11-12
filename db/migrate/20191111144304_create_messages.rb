class CreateMessages < ActiveRecord::Migration[5.2]
  def change
    create_table :messages do |t|
      t.string :text
      t.references :member, foreign_key: true, type: :integer
      t.references :chat_room, foreign_key: true

      t.timestamps
    end
  end
end
