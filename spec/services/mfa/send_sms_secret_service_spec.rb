# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mfa::SendSmsSecretService do
  let(:admin) { create(:admin) }
  let(:token) { access_token.token }
  let(:model) { Admin }
  let(:phone_number) { '+79136767372' }
  let(:params) do
    {
      token: token,
      model: model,
      phone_number: phone_number
    }
  end

  subject(:service) { described_class.new(params) }

  describe '#call' do
    subject(:call_service) { service.call }

    context 'when token are valid' do
      let!(:access_token) { create(:access_token, resource_owner_id: admin.id, scopes: 'mfa_login_admin') }

      before { allow(service).to receive(:send_sms_code).and_return(true) }

      it 'sends code and changes sms_secret_code in user`s attributes' do
        expect { call_service }.to(change { admin.reload.sms_secret_encrypted })
      end
    end

    context 'when token are invalid' do
      let!(:access_token) { create(:access_token, resource_owner_id: admin.id, scopes: 'mfa_login_admin') }
      let(:token) { Faker::Alphanumeric.alphanumeric(10) }

      it 'raises an Errors::UnknownToken' do
        expect { subject }.to raise_error(Errors::UnknownToken)
      end
    end
  end
end
