class Message < ApplicationRecord
  enum status: { published: 0, deleted: 1 }

  belongs_to :member
  belongs_to :chat_room
end
