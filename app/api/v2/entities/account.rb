# encoding: UTF-8
# frozen_string_literal: true

module API
  module V2
    module Entities
      class Account < Base
        expose(
          :asset,
          documentation: {
            desc: 'Currency name.',
            type: String
          }
        ) do |account, _options|
          ::Currency.find(account.currency_id).name
        end

        expose(
          :currency_id,
          as: :currency,
          documentation: {
            desc: 'Currency code.',
            type: String
          }
        )

        expose(
          :balance,
          format_with: :decimal,
          documentation: {
            desc: 'Account balance.',
            type: BigDecimal
          }
        )

        expose(
          :locked,
          format_with: :decimal,
          documentation: {
            desc: 'Account locked funds.',
            type: BigDecimal
          }
        )

        expose(
          :total,
          format_with: :decimal,
          documentation: {
            desc: 'Account total funds.',
            type: BigDecimal
          }
        ) do |account, _options|
          account.amount
        end
      end
    end
  end
end
