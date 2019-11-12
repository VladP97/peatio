module API::V2
  module Chat
    class Mount < Grape::API

      before { authenticate! }
      before { set_ets_context! }

      mount Chat::Messages
    end
  end
end