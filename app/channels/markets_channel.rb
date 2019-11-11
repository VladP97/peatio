class MarketsChannel < ApplicationCable::Channel
  def subscribed  
    stream_for market
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  private

  def market
    Market.find(params[:market])
  end
end
