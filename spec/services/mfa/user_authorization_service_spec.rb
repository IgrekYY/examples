# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mfa::UserAuthorizationService do
  let(:correct_email) { 'correct_email@mail.com' }
  let(:incorrect_email) { 'incorrect_email@mail.com' }
  let(:correct_password) { '4isdmdgahreojH!' }
  let(:incorrect_password) { 'incorrect_password' }
  let(:recovery_process) { true }
  let(:model) { Admin }
  let(:expires_in) { Constants::SHORT_TOKEN_EXPIRES_IN.to_i }
  let(:doorkeeper_token) { Doorkeeper::AccessToken }
  let(:scope) { 'mfa_login_admin' }
  let!(:admin) do
    create(:admin, password: correct_password, email: correct_email, in_mfa_recovery_process: recovery_process)
  end

  let(:params) do
    {
      email: email,
      password: correct_password,
      model: model,
      expires_in: expires_in,
      scope: scope
    }
  end

  before do
    allow_any_instance_of(described_class).to receive(:user_blocked?).and_return(false)
    allow_any_instance_of(described_class).to receive(:reset_attempts_counter).and_return('OK')
    allow(Rails.application.config).to receive(:mfa_procedure_enabled).and_return(true)
    allow_any_instance_of(described_class).to receive(:incr_failed_attempts_counter).and_return('OK')
  end

  subject { described_class.perform(params) }

  describe '#call' do
    let(:email) { correct_email }

    context 'when credentials are correct' do
      context 'and mfa_procedure is enabled globally' do
        it 'returns a new token with `mfa_login_admin` scope' do
          subject
          expect(doorkeeper_token.last.scopes.to_s).to eq('mfa_login_admin')
        end

        context 'and user has already requested mfa recovery and hasn`t recieved recovery params yet' do
          it { is_expected.to include(is_in_mfa_recovery_process: true, is_mfa_recovery_params_expired: false) }
        end

        context 'and user has already requested mfa recovery and has recovery params expired' do
          let!(:mfa_recovery) do
            create(:mfa_recovery,
                   code: '123456',
                   expires_at: Time.now - 1.hour,
                   applied_at: nil,
                   record_owner: admin,
                   token: 'token')
          end

          it { is_expected.to include(is_in_mfa_recovery_process: true, is_mfa_recovery_params_expired: true) }
        end

        context 'and user dont have any recovery params' do
          let(:recovery_process) { false }

          it { is_expected.to include(is_in_mfa_recovery_process: false, is_mfa_recovery_params_expired: false) }
        end
      end

      context 'and mfa_procedure is disabled globally' do
        before { allow(Rails.application.config).to receive(:mfa_procedure_enabled).and_return(false) }

        context 'and user is blocked' do
          before { allow_any_instance_of(described_class).to receive(:user_blocked?).and_return(true) }

          it 'raises an Errors::UserTemporaryBlocked' do
            expect { subject }.to raise_error(Errors::UserTemporaryBlocked)
          end
        end

        context 'and user is not blocked' do
          it 'returns a new token with `admin` scope' do
            subject
            expect(doorkeeper_token.last.scopes.to_s).to eq('admin')
          end
        end
      end
    end

    context 'when credentials are invalid' do
      let(:email) { incorrect_email }

      it 'raises an Errors::InvalidPasswordOrEmail' do
        expect { subject }.to raise_error(Errors::InvalidPasswordOrEmail)
      end
    end
  end
end
