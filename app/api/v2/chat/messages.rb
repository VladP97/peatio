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
        post '/message/send' do
          chat_room = ChatRoom.find_by(lang: params[:lang])
          message = Message.create(
              text: params[:text],
              member_id: current_user[:id],
              chat_room_id: chat_room[:id])
          ChatsChannel.broadcast_to chat_room, id: message.id, text: message.text, uid: current_user[:uid]
        end

        desc 'Delete message'
        params do
          requires :id,
                   type: { value: Integer, message: 'chat.message.empty_message_id' },
                   allow_blank: false,
                   desc: 'Delete user message.'
        end
        delete '/message/delete' do
          error!({ errors: ['market.order.incorrect_user_role'] }, 401) unless current_user.admin?
          message = Message.find(params[:id])
          message.update(satus: :deleted)
          ChatsChannel.broadcast_to chat_room, id: message.id, text: message.text, uid: current_user[:uid]
          status(200)
        end

        desc 'Get room messages'
        get '/messages/:room_lang' do
          messages = ChatRoom.find_by(lang: params[:room_lang]).messages.where(status: :published).last(100)
          messages.map { |message| {'text' => message[:text], 'uid' => message.member[:uid]} }
        end
      end
    end
  end
end
