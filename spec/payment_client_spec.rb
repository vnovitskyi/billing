require_relative '../payment_client'

RSpec.describe PaymentClient do
  let(:payment_client) { PaymentClient.new }
  let(:subscription_id) { 'sub_12345' }
  let(:amount) { 100.00 }

  describe '#create_payment' do
    subject(:create_payment) { payment_client.create_payment(subscription_id, amount) }

    context 'when there is not network error' do
      let(:response_instance) { instance_double(Net::HTTPResponse, body: { status: status }.to_json) }

      before do
        allow(Net::HTTP).to receive(:start).and_return(response_instance)
      end

      context 'when payment is successful' do
        let(:status) { 'success' }
        
        it 'returns success status' do
          expect(create_payment).to eq('success')
        end
      end

      context 'when insufficient funds' do
        let(:status) { 'insufficient_funds' }
        
        it 'returns insufficient_funds status' do
          expect(create_payment).to eq('insufficient_funds')
        end
      end

      context 'when payment fails' do
        let(:status) { 'failed' }

        it 'returns failed status' do
          expect(create_payment).to eq('failed')
        end
      end
    end

    context 'when there is a network error' do
      before do
        allow(Net::HTTP).to receive(:start).and_raise(StandardError.new('Network Error'))
      end

      it 'raises a PaymentClientError' do
        expect do
          create_payment
        end.to raise_error(PaymentClient::PaymentClientError, /Payment API error: Network Error/)
      end
    end
  end
end
