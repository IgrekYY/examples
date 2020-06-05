# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mfa::SmsSenderService do
  let(:params) do
    {
      message: 'test',
      phone_number: phone_number
    }
  end
  let(:call_service_with_rescue) do
    service.call
  rescue Twilio::REST::RestError
    nil
  end
  let(:call_service) { service.call }

  subject(:service) { described_class.new(params) }

  describe '#call' do
    context 'when phone number incorrect' do
      let(:phone_number) { '89136767372' }

      it 'writes to log Twilio::REST::RestError ecxeption' do
        expect(subject).to receive(:log_error).with(Twilio::REST::RestError)
        call_service_with_rescue
      end

      it 'raises Twilio::REST::RestError' do
        expect { call_service }.to raise_error(Twilio::REST::RestError)
      end
    end
  end
end
