# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mfa::ResetService do
  let(:manager) { create(:admin, mfa_method: 1, in_mfa_recovery_process: true) }
  let(:expires_at) { Time.now + 1.hour }
  let(:applied_at) { nil }
  let(:code) { '123456' }
  let(:token) { 'correct_token' }
  let(:param_token) { 'correct_token' }
  let(:param_code) { '123456' }
  let(:param_email) { manager.email }
  let(:param_password) { manager.password }
  let!(:mfa_recovery) do
    create(:mfa_recovery,
           code: code,
           expires_at: expires_at,
           applied_at: applied_at,
           record_owner: manager,
           token: token)
  end
  let(:params) do
    {
      code: param_code,
      email: param_email,
      password: param_password,
      token: param_token
    }
  end
  let(:call_service_with_rescue) do
    service.call
  rescue StandardError
    nil
  end
  let(:call_service) { service.call }

  subject(:service) { described_class.new(params) }

  before do
    allow_any_instance_of(described_class).to receive(:user_blocked?).and_return(false)
    allow_any_instance_of(described_class).to receive(:reset_attempts_counter).and_return('OK')
    allow_any_instance_of(described_class).to receive(:incr_failed_attempts_counter).and_return('OK')
  end

  describe '#call' do
    context 'when token is invalid' do
      let(:param_token) { 'wrong_token' }

      it 'raises an Errors::UnknownResetMfaToken' do
        expect { call_service }.to raise_error(Errors::UnknownResetMfaToken)
      end
    end

    context 'when token is valid' do
      context 'and recovery params are not valid' do
        context 'because they are expired' do
          let(:expires_at) { Time.now - 2.hours }

          it 'writes to log ExpiredRecoveryParams exeption' do
            expect(subject).to receive(:log_error).with(Errors::ExpiredRecoveryParams)
            call_service_with_rescue
          end

          it 'raises an Errors::InvalidMfaRecoveryParams' do
            expect { call_service }.to raise_error(Errors::InvalidMfaRecoveryParams)
          end
        end

        context 'because they have already used' do
          let(:applied_at) { Time.now }

          it 'writes to log RecoveryParamsAlreadyUsed exeption' do
            expect(subject).to receive(:log_error).with(Errors::RecoveryParamsAlreadyUsed)
            call_service_with_rescue
          end

          it 'raises an Errors::InvalidMfaRecoveryParams' do
            expect { call_service }.to raise_error(Errors::InvalidMfaRecoveryParams)
          end
        end
      end

      context 'and recovery params are valid' do
        context 'and code is incorrect' do
          let(:param_code) { '456789' }

          it 'writes to log InvalidMfaRecoveryCode exeption' do
            expect(subject).to receive(:log_error).with(Errors::InvalidMfaRecoveryCode)
            call_service_with_rescue
          end

          it 'raises an Errors::InvalidMfaRecoveryParams' do
            expect { call_service }.to raise_error(Errors::InvalidMfaRecoveryParams)
          end
        end

        context 'and email or password is invalid' do
          let(:param_email) { 'wrong_email' }

          it 'writes to log UnknownUser exeption' do
            expect(subject).to receive(:log_error).with(Errors::UnknownUser)
            call_service_with_rescue
          end

          it 'raises an Errors::InvalidMfaRecoveryParams' do
            expect { call_service }.to raise_error(Errors::InvalidMfaRecoveryParams)
          end
        end

        context 'and code is correct' do
          it 'changes user profile, marks recovery params as `applied` and returns access token ' do
            expect { call_service }.to(
              (change { manager.reload.mfa_method })
              .and(change { manager.reload.in_mfa_recovery_process })
              .and(change { mfa_recovery.reload.applied_at })
              .and(change(Doorkeeper::AccessToken, :count))
            )
          end
        end
      end
    end
  end
end
