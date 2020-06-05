# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mfa::VerifyAndSaveNewAppService do
  let(:admin) { create(:admin) }
  let(:access_token) { create(:access_token, resource_owner_id: admin.id, scopes: 'mfa_login_admin') }
  let(:verification_code) { '256879' }
  let(:secret_code) { 'X4BSUXDKYC4OWXXCB6J7UPJU75G5Y3CI' }
  let(:token) { access_token.token }
  let(:generate_token) { nil }
  let(:params) do
    {
      verification_code: verification_code,
      secret_code: secret_code,
      token: token,
      generate_token: generate_token
    }
  end

  subject(:service) { described_class.new(params) }

  describe '#call' do
    subject(:call_service) { service.call }

    context 'when verification code is incorrect' do
      before { allow(service).to receive(:verification_code_valid?).and_return(false) }

      it 'raises an Errors::InvalidVerificationCode' do
        expect { subject }.to raise_error(Errors::InvalidVerificationCode)
      end
    end

    context 'when verification code is correct' do
      before { allow(service).to receive(:verification_code_valid?).and_return(true) }

      context 'and user has `phone_number` as a current mfa method' do
        context 'and param generate_token is passed with `true`' do
          let(:generate_token) { true }
          let(:admin) { create(:admin, mfa_method: 1, mfa_phone: '+794568264456748') }

          it 'changes 3 attrubutes of user: totp_secret_encrypted, mfa_method, mfa_phone' do
            expect { call_service }.to(
              (change { admin.reload.totp_secret_encrypted })
              .and(change { admin.reload.mfa_method })
              .and(change { admin.reload.mfa_phone })
            )
          end

          it 'returns a new token' do
            expect { call_service }.to change { Doorkeeper::AccessToken.count }.by(1)
          end
        end
      end

      context 'and user has `application` as a current mfa method' do
        context 'and param generate_token didn`t pass' do
          let(:admin) { create(:admin, mfa_method: 0) }

          it 'changes only 1 attrubute of user: totp_secret_encrypted' do
            expect { call_service }.to(change { admin.reload.totp_secret_encrypted })
          end

          it 'isnt returns a new token' do
            expect { call_service }.not_to(change { Doorkeeper::AccessToken.count })
          end
        end
      end
    end
  end
end
