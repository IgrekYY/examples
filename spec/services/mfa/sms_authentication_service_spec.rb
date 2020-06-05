# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mfa::SmsAuthenticationService do
  let(:admin) { create(:admin) }
  let(:token) { access_token.token }
  let(:sms_code) { '555555' }
  let(:params) do
    {
      token: token,
      sms_code: sms_code
    }
  end

  before do
    allow_any_instance_of(described_class).to receive(:user_blocked?).and_return(false)
    allow_any_instance_of(described_class).to receive(:reset_attempts_counter).and_return('OK')
    allow_any_instance_of(described_class).to receive(:incr_failed_attempts_counter).and_return('OK')
  end

  subject(:service) { described_class.new(params) }

  describe '#call' do
    subject(:call_service) { service.call }

    let!(:access_token) { create(:access_token, resource_owner_id: admin.id, scopes: 'mfa_login_admin') }

    context 'when token is valid' do
      context 'and sms code is incorrect' do
        it 'raises an Errors::InvalidVerificationCode' do
          expect { subject }.to raise_error(Errors::InvalidVerificationCode)
        end
      end

      context 'and user is blocked' do
        before { allow_any_instance_of(described_class).to receive(:user_blocked?).and_return(true) }

        it 'raises an Errors::UserTemporaryBlocked' do
          expect { subject }.to raise_error(Errors::UserTemporaryBlocked)
        end
      end

      context 'and sms code is correct' do
        before do
          admin.sms_secret = '555555'
          admin.sms_secret_created_at = Time.now
          admin.save!
        end

        it 'returns a new standart access token' do
          expect { call_service }.to(
            change(Doorkeeper::AccessToken, :count)
            .and(change { admin.reload.sms_secret_encrypted })
            .and(change { admin.reload.sms_secret_created_at })
          )
        end
      end
    end

    context 'when token is invalid' do
      let(:token) { Faker::Alphanumeric.alphanumeric(10) }

      it 'raises an Errors::UnknownToken' do
        expect { call_service }.to raise_error(Errors::UnknownToken)
      end
    end
  end
end
