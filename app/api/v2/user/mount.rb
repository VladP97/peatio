module API::V2
  module User
    class Mount < Grape::API

      helpers ::API::V2::StatisticsHelper

      before { authenticate! }
      before { set_ets_context! }

      mount User::Statistics
    end
  end
end