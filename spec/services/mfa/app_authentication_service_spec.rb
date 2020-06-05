# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mfa::AppAuthenticationService do
  let(:admin) { create(:admin) }
  let(:token) { access_token.token }
  let(:model) { Admin }
  let(:verification_code) { '256879' }
  let(:params) do
    {
      token: token,
      model: model,
      verification_code: verification_code
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
      context 'and verification code is incorrect' do
        before { allow(service).to receive(:verification_code_valid?).and_return(false) }

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

      context 'and verification code is correct' do
        before { allow(service).to receive(:verification_code_valid?).and_return(true) }

        it 'return a new standart access token' do
          expect { call_service }.to change { Doorkeeper::AccessToken.count }.by(1)
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
