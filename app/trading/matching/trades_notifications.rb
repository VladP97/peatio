module Matching
  class TradesNotifications
    def notify(trade, market)
      header_service = HeaderService.new(market)
      trade_with_min_price, trade_with_max_price = header_service.trades_with_min_max_price
      TradesChannel.broadcast_to market, \
        trade: trade, \
        min_price: trade_with_min_price.price, \
        max_price: trade_with_max_price.price, \
        volume: header_service.sum_of_daily_trades, \
        diff: header_service.price_diff(trade)
    end
  end
end