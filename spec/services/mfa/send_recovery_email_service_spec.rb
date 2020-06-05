# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mfa::SendRecoveryEmailService do
  let(:account) { create(:account) }
  let(:manager) { create(:manager, account: account) }
  let(:admin) { create(:admin) }
  let(:admin_root) { create(:admin, role: 0) }
  let(:token) { access_token.token }
  let(:params) { { token: token } }
  let(:manager_mailer_mock) { double('ManagerMailer mock') }
  let(:action_mailer_mock) { double('ActionMailer mock', deliver_now: nil) }
  let(:action_mailer_mock2) { double('ActionMailer mock', deliver_now: nil) }
  let(:user) { manager }

  subject(:service) { described_class.new(params) }

  describe '#call' do
    subject(:call_service) { service.call }

    let!(:access_token) { create(:access_token, resource_owner_id: user.id, scopes: 'mfa_login_manager') }

    context 'when token is valid' do
      before { allow_any_instance_of(Mfa::SendRecoveryEmailService).to receive(:user).and_return(user) }

      it 'changes user`s mfa recovery status' do
        expect { call_service }.to change(user, :mfa_recovery_requested_at).and change(user, :in_mfa_recovery_process)
      end

      context 'and user is manager and not owner' do
        it 'sends email about MFA reset to the user and his headquorter' do
          allow(user).to receive(:mailer).and_return(manager_mailer_mock)
          expect(manager_mailer_mock).to receive(:reset_mfa_request_to_self_other).and_return(action_mailer_mock)
          expect(manager_mailer_mock).to receive(:reset_mfa_request_to_owner).and_return(action_mailer_mock2)
          expect(action_mailer_mock).to receive(:deliver_now)
          expect(action_mailer_mock2).to receive(:deliver_now)
          call_service
        end
      end

      context 'and user is manager and owner' do
        let(:user) { account.managers.find_by(role: 0) }

        it 'sends email about MFA reset to the MetroEngine' do
          allow(user).to receive(:mailer).and_return(manager_mailer_mock)
          expect(manager_mailer_mock).to receive(:reset_mfa_request_to_self_hq).and_return(action_mailer_mock)
          expect(manager_mailer_mock).to receive(:reset_mfa_request_to_metroengine).and_return(action_mailer_mock2)
          expect(action_mailer_mock).to receive(:deliver_now)
          expect(action_mailer_mock2).to receive(:deliver_now)
          call_service
        end
      end

      context 'and user is admin with `root` role' do
        let(:user) { admin_root }

        it 'sends no emails' do
          allow(user).to receive(:mailer).and_return(manager_mailer_mock)
          expect(manager_mailer_mock).not_to receive(:reset_mfa_request_to_owner)
          call_service
        end
      end

      context 'and user is admin with not `root` role' do
        let(:user) { admin }

        it 'sends email about MFA reset only to self and root admin' do
          allow(user).to receive(:mailer).and_return(manager_mailer_mock)
          expect(manager_mailer_mock).to receive(:reset_mfa_request_to_self).and_return(action_mailer_mock)
          expect(manager_mailer_mock).to receive(:reset_mfa_request_to_root).and_return(action_mailer_mock2)
          expect(action_mailer_mock).to receive(:deliver_now)
          expect(action_mailer_mock2).to receive(:deliver_now)
          call_service
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
