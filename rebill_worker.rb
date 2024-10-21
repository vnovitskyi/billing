require_relative 'subscription_charger'

class RebillWorker
  def perform(subscription_id, amount)
    SubscriptionCharger.new(subscription_id, amount).charge
  end
end
