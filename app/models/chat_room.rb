# encoding: UTF-8
# frozen_string_literal: true

class ChatRoom < ApplicationRecord
  has_many :messages
end