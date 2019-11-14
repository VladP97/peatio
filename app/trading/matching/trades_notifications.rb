module Matching
  class TradesNotifications < HeaderService
    def notify(trade, market_to_notify)
      market = market_to_notify
      trade_with_min_price, trade_with_max_price = trades_with_min_max_price
      TradesChannel.broadcast_to market, \
        trade: trade, \
        min_price: trade_with_min_price.price, \
        max_price: trade_with_max_price.price, \
        volume: sum_of_daily_trades, \
        diff: price_diff(trade)
    end
  end
end