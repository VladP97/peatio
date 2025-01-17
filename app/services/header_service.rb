class HeaderService

  def initialize(initial_market)
    @market = initial_market
  end

  def trades_with_min_max_price
    min, max = last_24_hours_trades_for_market.minmax_by { |trade| trade.price }
    if min && max
      [min.price, max.price]
    else
      [0.0, 0.0]
    end
  end

  def price_diff(trade)
    price_diff = last_24_hours_trades_for_market.first.price - trade.price
    (price_diff / last_24_hours_trades_for_market.first.price).round(2)
  rescue
    0.0
  end

  def sum_of_daily_trades
    last_24_hours_trades_for_market.sum(:total).to_f
  end

  def last_24_hours_trades_for_market
    @last_24_hours_trades ||= Trade.where(updated_at: (Time.now - 24.hours)..Time.now, market_id: market_id)
  end

  def market_id
    @market_id ||= @market.id rescue ''
  end

  def market
    @market
  end

  def market=(new_market)
    @market = new_market
  end
end