require_relative '../payment_client'
require_relative '../subscription_charger'

RSpec.describe SubscriptionCharger do
  let(:subscription_id) { 'sub_12345' }
  let(:amount) { 100.00 }
  let(:subscription_charger) { described_class.new(subscription_id, amount) }
  let(:payment_client) { instance_double(PaymentClient) }

  before do
    allow(PaymentClient).to receive(:new).and_return(payment_client)
  end

  describe '#charge' do
    context 'when the full payment is successful' do
      before do
        allow(payment_client).to receive(:create_payment).and_return('success')
      end

      it 'logs a successful payment' do
        expect do
          subscription_charger.charge
        end.to output(/Payment successful for subscription `#{subscription_id}` total amount/).to_stdout_from_any_process
      end
    end

    context 'when the payment is partially successful' do
      before do
        allow(payment_client).to receive(:create_payment).and_return('insufficient_funds', 'insufficient_funds',
                                                                     'success')
      end

      it 'schedules a remaining payment' do
        expect(RebillWorker).to receive(:perform_in).with(604800, subscription_id, 50.00)
        expect { subscription_charger.charge }.to output(/Scheduled additional transaction/).to_stdout_from_any_process
      end
    end

    context 'when all payment attempts fail' do
      before do
        allow(payment_client).to receive(:create_payment).and_return('insufficient_funds', 'insufficient_funds',
                                                                     'insufficient_funds', 'failed')
      end

      it 'logs that the payment failed' do
        expect { subscription_charger.charge }.to output(/Payment failed/).to_stdout_from_any_process
      end
    end

    context 'when there is a PaymentClientError' do
      before do
        allow(payment_client).to receive(:create_payment).and_raise(PaymentClient::PaymentClientError.new('API Error'))
      end

      it 'logs the error' do
        expect do
          subscription_charger.charge
        end.to output(/PaymentClientError during payment attempt: API Error/).to_stdout_from_any_process
      end
    end
  end
end
