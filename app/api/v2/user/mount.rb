module API::V2
  module User
    class Mount < Grape::API

      before { authenticate! }
      before { set_ets_context! }

      mount User::Statistics
    end
  end
end