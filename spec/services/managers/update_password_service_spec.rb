# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Managers::UpdatePasswordService do
  let(:token) { Faker::Alphanumeric.alphanumeric(10) }
  let(:password) { '4isdmdgahreojH!' }
  let(:manager) { create(:manager) }
  let(:manager_class) { Manager }
  let(:doorkeeper_token) { Doorkeeper::AccessToken }
  let(:access_token) { create(:access_token, resource_owner_id: manager.id, scopes: 'manager') }
  let(:params) { { token: token, password: '4isdmdgahreojH!' } }

  subject(:service_call) { described_class.perform(params) }

  describe 'perform operation failed' do
    context 'when token is invalid or expired' do
      before do
        allow(manager_class).to receive(:with_reset_password_token).and_return(nil)
      end

      it 'raises Errors::UnknownResetPasswordToken' do
        expect { service_call }.to raise_error(Errors::UnknownResetPasswordToken)
      end
    end

    context 'when password is invalid' do
      let(:params) { { password: '2314124fa' } }

      before do
        allow(manager_class).to receive(:with_reset_password_token).and_return(manager)
      end

      it 'raises Errors::UnacceptablePassword' do
        expect { service_call }.to raise_error(Errors::UnacceptablePassword)
      end
    end
  end

  describe 'perform operation is successful' do
    context 'when password is valid' do
      before do
        allow(manager_class).to receive(:with_reset_password_token).and_return(manager)
      end

      it 'updates manager with new password' do
        expect { service_call }.to(change(manager, :password).to(password)
                               .and(change(manager, :is_new_policy_password).to(true)))
      end

      context 'and mfa_procedure is enabled globally' do
        before { allow(Rails.application.config).to receive(:mfa_procedure_enabled).and_return(true) }

        it 'returns a new token with `mfa_login_manager` scope' do
          service_call
          expect(doorkeeper_token.last.scopes.to_s).to eq('mfa_login_manager')
        end
      end

      context 'and mfa_procedure is disabled globally' do
        before { allow(Rails.application.config).to receive(:mfa_procedure_enabled).and_return(false) }

        it 'returns a new token with `manager` scope' do
          service_call
          expect(doorkeeper_token.last.scopes.to_s).to eq('manager')
        end
      end
    end
  end
end
