class Message < ApplicationRecord
  belongs_to :member
  belongs_to :chat_room
end
