module API
  module V2
    module User
      class Statistics < Grape::API

        desc 'Get basic exchange statistics'
        get '/statistics' do
          currencies_count = Currency.count
          all_members = Member.count
          active_members = Member.joins(:orders).uniq.count
          { assets: currencies_count, members: all_members, active_members: active_members }
        end
      end
    end
  end
end