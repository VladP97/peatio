module API
  module V2
    module Chat
      class Messages < Grape::API
        desc 'Create message'
        params do
          requires :text,
                   type: { value: String, message: 'chat.message.empty_message' },
                   allow_blank: false,
                   desc: 'Text of chat message'
          requires :lang,
                   type: { value: String, message: 'chat.message.empty_lang' },
                   allow_blank: false,
                   desc: 'Room lang'
        end
        post '/send' do
          chat_room = ChatRoom.find_by(lang: params[:lang])
          message = Message.create(
              text: params[:text],
              member_id: current_user[:id],
              chat_room_id: chat_room[:id])
          ChatsChannel.broadcast_to chat_room, text: message.text, uid: current_user[:uid]
        end
      end
    end
  end
end