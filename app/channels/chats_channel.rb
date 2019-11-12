class ChatsChannel < ApplicationCable::Channel
  def subscribed
    stream_for chat_room
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  private

  def chat_room
    ChatRoom.find_by(lang: params[:lang])
  end
end