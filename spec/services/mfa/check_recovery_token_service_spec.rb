# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mfa::CheckRecoveryTokenService do
  let(:manager) { create(:manager) }
  let!(:mfa_recovery) do
    create(:mfa_recovery,
           code: '123456',
           expires_at: expires_at,
           applied_at: applied_at,
           record_owner: manager,
           token: token)
  end
  let(:token) { 'wTZ4C3Et6FZWsZfScQ5LdvxJ' }
  let(:param_token) { 'wTZ4C3Et6FZWsZfScQ5LdvxJ' }
  let(:expires_at) { Time.now + 1.hour }
  let(:applied_at) { nil }
  let(:params) { { token: param_token } }

  subject(:service) { described_class.new(params) }

  describe '#call' do
    subject(:call_service) { service.call }

    context 'when token is valid' do
      context 'and user is not presented' do
        before { manager.delete }

        it 'raises an Errors::UnknownUser' do
          expect { subject }.to raise_error(Errors::UnknownUser)
        end
      end

      context 'and recovery token already expired' do
        let(:expires_at) { Time.now - 1.hour }

        it 'raises an Errors::ExpiredRecoveryParams' do
          expect { subject }.to raise_error(Errors::ExpiredRecoveryParams)
        end
      end

      context 'and recovery token already expired' do
        let(:applied_at) { Time.now - 30.minutes }

        it 'raises an Errors::RecoveryParamsAlreadyUsed' do
          expect { subject }.to raise_error(Errors::RecoveryParamsAlreadyUsed)
        end
      end

      context 'and there are no errors in service' do
        it { is_expected.to be_nil }
      end
    end

    context 'when token is invalid' do
      let(:token) { Faker::Alphanumeric.alphanumeric(32) }

      it 'raises an Errors::UnknownResetMfaToken' do
        expect { subject }.to raise_error(Errors::UnknownResetMfaToken)
      end
    end
  end
end
