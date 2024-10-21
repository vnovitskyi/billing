# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

class PaymentClient
  class PaymentClientError < StandardError; end

  CREATE_PAYMENT_API_PATH = 'paymentIntents/create'

  def create_payment(subscription_id, amount)
    uri = URI.parse("#{host}#{CREATE_PAYMENT_API_PATH}")
    request = Net::HTTP::Post.new(uri)
    request.content_type = 'application/json'
    request.body = { 'amount' => amount, 'subscription_id' => subscription_id }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
    # response = Struct.new(:body).new('{"status": "insufficient_funds"}')

    result = JSON.parse(response.body)
    result['status']
  rescue StandardError => e
    raise PaymentClientError, "Payment API error: #{e.message}"
  end

  private

  def host
    'http://localhost/' # Can dynamically configure the host based on the environment
  end
end
