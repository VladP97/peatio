# encoding: UTF-8
# frozen_string_literal: true

require_relative 'constants'

module Matching
  class Executor
    ExecutorError = Class.new(StandardError)

    def initialize(payload)
      @payload = payload
      @trade_payload = payload[:trade].symbolize_keys if payload[:trade]
      @trades_notifications = TradesNotifications.new
    end

    def process
      case @payload[:action]
      when 'execute'
        execute
      when 'cancel'
        publish_cancel
      else
        raise ExecutorError.new("Unknown action: #{@payload[:action]}")
      end
    end

    def publish_cancel
      AMQPQueue.enqueue(:order_processor,
                        { action: 'cancel', order: @payload[:order] },
                        { persistent: false })
    end

    def execute
      execute!
      # TODO: Queue should exist event if none is listening.
    rescue TradeExecutionError => e
      AMQPQueue.enqueue(:trade_error, e.options)
      [@maker_order, @taker_order].each do |order|
        order.with_lock do
          next unless order.state == Order::WAIT
          AMQPQueue.enqueue(:matching, action: 'submit', order: order.to_matching_attributes)
        end
      end
      report_exception_to_screen(e)
      false
    end

    def execute!
      # NOTE: Run matching engine for disabled markets.
      @market = Market.find(@trade_payload[:market_id])
      @price  = @trade_payload[:strike_price].to_d
      @amount = @trade_payload[:amount].to_d
      @total  = @trade_payload[:total].to_d

      create_trade_and_strike_orders
      publish_trade
      @trades_notifications.notify(@trade, @market)
      @trade
    end

  private

    def validate!
      ask, bid = @maker_order.side == 'sell' ? [@maker_order, @taker_order] : [@taker_order, @maker_order]
      raise_error(3001, 'Ask price exceeds strike price.') if ask.ord_type == 'limit' && ask.price > @price
      raise_error(3002, 'Bid price is less than strike price.') if bid.ord_type == 'limit' && bid.price < @price
      raise_error(3003, "Maker order state isn\'t equal to «wait» (#{@maker_order.state}).") unless @maker_order.state == Order::WAIT
      raise_error(3004, "Taker order state isn\'t equal to «wait» (#{@taker_order.state}).") unless @taker_order.state == Order::WAIT
      unless @total > ZERO && [@maker_order.volume, @taker_order.volume].min >= @amount
        raise_error(3005, 'Not enough funds.')
      end
    end

    def create_trade_and_strike_orders
      ActiveRecord::Base.transaction do
        Order.lock.where(id: [@trade_payload[:maker_order_id], @trade_payload[:taker_order_id]])
             .includes(:ask_currency, :bid_currency)
             .to_a
             .tap do |orders|
          @maker_order = orders.find { |order| order.id == @trade_payload[:maker_order_id] }
          @taker_order = orders.find { |order| order.id == @trade_payload[:taker_order_id] }
        end

        validate!

        accounts_table = Account
          .lock
          .select(:id, :member_id, :currency_id, :balance, :locked)
          .where(member_id: [@maker_order.member_id, @taker_order .member_id].uniq, currency_id: [@market.base_unit, @market.quote_unit])
          .each_with_object({}) { |record, memo| memo["#{record.currency_id}:#{record.member_id}"] = record }

        @trade = Trade.new \
          maker_order:   @maker_order,
          maker_id:      @maker_order.member_id,
          taker_order:   @taker_order,
          taker_id:      @taker_order.member_id,
          price:         @price,
          amount:        @amount,
          total:         @total,
          market:        @market

        strike(@trade, @maker_order, accounts_table["#{@maker_order.outcome_currency.id}:#{@maker_order.member_id}"], accounts_table["#{@maker_order.income_currency.id}:#{@maker_order.member_id}"])
        strike(@trade, @taker_order, accounts_table["#{@taker_order.outcome_currency.id}:#{@taker_order.member_id}"], accounts_table["#{@taker_order.income_currency.id}:#{@taker_order.member_id}"])
        @trade.record_complete_operations!

        ([@maker_order, @taker_order] + accounts_table.values).map do |record|
          table     = record.class.arel_table
          statement = Arel::UpdateManager.new
          statement.table(table)
          statement.where(table[:id].eq(record.id))
          updates = record.changed_attributes.map do |(attribute, _)|
            if Order === record
              value = record.public_send(attribute)
              [table[attribute], ::Order::STATES.with_indifferent_access.fetch(value, value)]
            else
              [table[attribute], record.public_send(attribute)]
            end
          end
          statement.set updates
          statement.to_sql
        end.join('; ').tap do |sql|
          Rails.logger.debug { sql }
          client = ActiveRecord::Base.connection.raw_connection
          client.query(sql)
          while client.next_result
          end
        end

        @trade.save(validate: false)
      end
    end

    def publish_trade
      AMQPQueue.publish :trade, @trade.as_json, {
        headers: {
          market:        @market.id,
          maker_id: @maker_id,
          taker_id: @taker_id
        }
      }

      [@maker_order, @taker_order].each do |order|
        event =
          case order.state
          when 'cancel' then 'order_canceled'
          when 'done'   then 'order_completed'
          else 'order_updated'
          end

        order.trigger_pusher_event
        next unless order.ord_type == 'limit' # Skip market orders.

        EventAPI.notify ['market', order.market_id, event].join('.'), \
          Serializers::EventAPI.const_get(event.camelize).call(order)
      end
    end

    def raise_error(code, message)
      raise TradeExecutionError.new \
        maker_order: @maker_order.attributes,
        taker_order: @taker_order.attributes,
        price:       @price,
        amount:      @amount,
        total:       @total,
        code:        code,
        message:     message
    end

    def strike(trade, order, outcome_account, income_account)
      outcome_value, income_value = OrderAsk === order ? [trade.amount, trade.total] : [trade.total, trade.amount]
      fee = income_value * trade.order_fee(order)
      real_income_value = income_value - fee

      outcome_account.assign_attributes outcome_account.attributes_after_unlock_and_sub_funds!(outcome_value)
      income_account.assign_attributes income_account.attributes_after_plus_funds!(real_income_value)

      order.volume         -= trade.amount
      order.locked         -= outcome_value
      order.funds_received += income_value
      order.trades_count   += 1
      order.updated_at      = Time.now

      if order.volume.zero?
        order.state = Order::DONE

        # Unlock not used funds.
        unless order.locked.zero?
          outcome_account.assign_attributes outcome_account.attributes_after_unlock_funds!(order.locked)
        end
      elsif order.ord_type == 'market' && order.locked.zero?
        # Partially filled market order has run out it's locked funds.
        order.state = Order::CANCEL
        order.record_cancel_operations!
      end
    end
  end
end
