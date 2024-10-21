# frozen_string_literal: true

require_relative 'subscription_charger'

# Example usage:
subscription_id = 'sub_12345'
amount = 100.00

SubscriptionCharger.new(subscription_id, amount).charge
