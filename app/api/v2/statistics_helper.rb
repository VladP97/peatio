module API
  module V2
    module StatisticsHelper

      def exchange_rates
        markets = ::Market.all

        exchange_pairs = markets.map do |market|
          next unless market.id[/usd/]
          trade = Trade.find_by(market_id: market.id)
          next unless trade
          [market.id[/(.*?)usd/, 1], trade.price]
        end.compact

        Hash[exchange_pairs]
      end
    end
  end
end