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

        desc 'Get main wallet'
        get '/main-wallet' do
          accounts = current_user.accounts
          usd_exchange_rates = exchange_rates

          usd_sum = accounts.sum do |account|
            usd_exchange_rates.fetch(account.currency_id, 0) * account.balance
          end

          {usd_sum: usd_sum, btc_sum: (usd_sum / usd_exchange_rates['btc'] rescue 0)}
        end
      end
    end
  end
end