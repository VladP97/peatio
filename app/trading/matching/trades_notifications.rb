module Matching
  class TradesNotifications

    ORDER_TYPES = {
        'OrderBid' => :order_bid,
        'OrderAsk' => :order_ask
    }

    def notify(trade, market)
      header_service = HeaderService.new(market)
      trade_with_min_price, trade_with_max_price = header_service.trades_with_min_max_price
      volume = header_service.sum_of_daily_trades
      diff = header_service.price_diff(trade)
      TradesChannel.broadcast_to market, \
        trade: trade, \
        header: get_header_info(trade_with_min_price, trade_with_max_price, volume, diff), \
        trade_orders: get_trade_orders([Order.find(trade.taker_order_id), Order.find(trade.maker_order_id)])
    end

    private

    def get_header_info(trade_with_min_price, trade_with_max_price, volume, diff)
      {
        min_price: trade_with_min_price,
        max_price: trade_with_max_price,
        volume: volume,
        diff: diff
      }
    end

    def get_trade_orders(orders)
      Hash[orders.map { |order| [ORDER_TYPES[order.type], order] }]
    end
  end
end
