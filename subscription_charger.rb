# frozen_string_literal: true

require 'logger'
require_relative 'payment_client'
require_relative 'rebill_worker'

class SubscriptionCharger
  def initialize(subscription_id, amount)
    @subscription_id = subscription_id
    @original_amount = amount
    @logger = Logger.new($stdout)
    @payment_client = PaymentClient.new
  end

  def charge
    fractions = [1.0, 0.75, 0.5, 0.25]

    fractions.each do |fraction|
      attempt_amount = (@original_amount * fraction).round(2)

      begin
        payment_operation_status = @payment_client.create_payment(@subscription_id, attempt_amount)
        log_attempt(@subscription_id, attempt_amount, payment_operation_status)

        case payment_operation_status
        when 'success'
          handle_success(attempt_amount)
          break
        when 'failed'
          @logger.info("Payment failed for amount: #{attempt_amount}")
          break
        when 'insufficient_funds'
          @logger.info("Insufficient funds for amount: #{attempt_amount}")
          next
        else
          @logger.error("Unknown status received: #{payment_operation_status}")
          break
        end
      rescue PaymentClient::PaymentClientError => e
        @logger.error("PaymentClientError during payment attempt: #{e.message}")
        break
      rescue StandardError => e
        @logger.error("Exception during payment attempt: #{e.message}")
        break
      end
    end
  end

  private

  def log_attempt(subscription_id, amount, status)
    @logger.info("Attempted to charge subscription #{subscription_id} amount #{amount}: #{status}")
  end

  def handle_success(paid_amount)
    if @original_amount == paid_amount
      @logger.info("Payment successful for subscription `#{@subscription_id}` total amount: #{paid_amount}")
    else
      remaining_amount = (@original_amount - paid_amount).round(2)

      @logger.info("Payment successful for subscription `#{@subscription_id}` partial amount: #{paid_amount}, remaining amount: #{remaining_amount}")
      schedule_additional_transaction(remaining_amount)
    end
  end

  def schedule_additional_transaction(amount)
    one_week_in_seconds = 60 * 60 * 24 * 7
    RebillWorker.perform_in(one_week_in_seconds, @subscription_id, amount)
    @logger.info("Scheduled additional transaction for subscription #{@subscription_id} amount #{amount} in 1 week.")
  end
end
