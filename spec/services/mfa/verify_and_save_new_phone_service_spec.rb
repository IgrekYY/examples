# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mfa::VerifyAndSaveNewPhoneService do
  let(:admin) { create(:admin) }
  let(:access_token) { create(:access_token, resource_owner_id: admin.id, scopes: 'mfa_login_admin') }
  let(:sms_code) { '256879' }
  let(:token) { access_token.token }
  let(:phone_number) { '+79136767371' }
  let(:generate_token) { nil }
  let(:params) do
    {
      sms_code: sms_code,
      phone_number: phone_number,
      token: token,
      generate_token: generate_token
    }
  end

  subject(:service) { described_class.new(params) }

  describe '#call' do
    subject(:call_service) { service.call }

    context 'when sms code is incorrect' do
      before { allow(service).to receive(:sms_code_valid?).and_return(false) }

      it 'raises an Errors::InvalidVerificationCode' do
        expect { subject }.to raise_error(Errors::InvalidVerificationCode)
      end
    end

    context 'when sms code is correct' do
      before { allow(service).to receive(:sms_code_valid?).and_return(true) }

      context 'and user has `application` as a current mfa method' do
        context 'and param generate_token is passed with `true`' do
          let(:generate_token) { true }
          let(:admin) do
            create(:admin,
                   mfa_method: 0,
                   totp_secret_encrypted: 'secret_hash',
                   sms_secret_created_at: Time.now,
                   sms_secret_encrypted: 'secret_hash')
          end

          it 'changes 5 attrubutes of user' do
            expect { call_service }.to(
              (change { admin.reload.totp_secret_encrypted })
              .and(change { admin.reload.mfa_method })
              .and(change { admin.reload.sms_secret_encrypted })
              .and(change { admin.reload.sms_secret_created_at })
              .and(change { admin.reload.mfa_phone })
            )
          end

          it 'returns a new token' do
            expect { call_service }.to change { Doorkeeper::AccessToken.count }.by(1)
          end
        end
      end

      context 'and user has `phone_number` as a current mfa method' do
        context 'and param generate_token didn`t pass' do
          let(:admin) do
            create(:admin,
                   mfa_method: 1,
                   mfa_phone: '+79136767372',
                   sms_secret_created_at: Time.now,
                   sms_secret_encrypted: 'secret_hash')
          end

          it 'changes only 3 attrubutes of user' do
            expect { call_service }.to(
              (change { admin.reload.sms_secret_encrypted })
              .and(change { admin.reload.sms_secret_created_at })
              .and(change { admin.reload.mfa_phone })
            )
          end

          it 'isnt returns a new token' do
            expect { call_service }.not_to(change { Doorkeeper::AccessToken.count })
          end
        end
      end
    end
  end
end
