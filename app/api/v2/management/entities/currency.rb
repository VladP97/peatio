# encoding: UTF-8
# frozen_string_literal: true

module API
  module V2
    module Management
      module Entities
        class Currency < ::API::V2::Entities::Currency

          expose(
            :visible,
            documentation: {
              type: String,
              desc: 'Currency display possibility status (true/false).'
            }
          )

          expose(
            :position,
            documentation: {
              type: Integer,
              desc: 'Currency position.'
            }
          )

          expose(
            :created_at,
            format_with: :iso8601,
            documentation: {
              type: String,
              desc: 'Currency created time in iso8601 format.'
            }
          )

          expose(
            :updated_at,
            format_with: :iso8601,
            documentation: {
              type: String,
              desc: 'Currency updated time in iso8601 format.'
            }
          )
        end
      end
    end
  end
end
