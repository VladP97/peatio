module Matching
  class TradesNotifications
    def notify(market, trade)
      trade_with_min_price, trade_with_max_price = trades_with_min_max_price
      price_diff(trade)
      TradesChannel.broadcast_to market, \
        trade: trade, \
        min_price: trade_with_min_price.price, \
        max_price: trade_with_max_price.price
    end

    private

    def last_24_hours_trades
      @last_24_hours_trades ||= Trade.where(updated_at: (Time.now - 24.hours)..Time.now)
    end

    def trades_with_min_max_price
      last_24_hours_trades.minmax_by { |trade| trade.price }
    end

    def price_diff(trade)
       (last_24_hours_trades.first.price - trade.price) / last_24_hours_trades.first.price
    end

    def sum_of_daily_trades
      last_24_hours_trades.sum { |trade| trade.total }
    end
  end
end