# billing

### Method: `schedule_additional_transaction`

The method `schedule_additional_transaction` simulates how a **Sidekiq** job would be used to schedule a background task for **rescheduling billing** in a Ruby application. Below is a breakdown of the code:

```ruby
def schedule_additional_transaction(amount)
  one_week_in_seconds = 60 * 60 * 24 * 7
  RebillWorker.perform_in(one_week_in_seconds, @subscription_id, amount)
  @logger.info("Scheduled additional transaction for subscription #{@subscription_id} amount #{amount} in 1 week.")
end


