# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::AuthController, type: :controller do
  render_views
  let(:email) { 'testtesttest@mail.com' }
  let(:password) { '4isdmdgahreojH!' }
  let!(:manager) { create(:manager, password: password, email: email) }
  let!(:access_token) { create(:access_token, resource_owner_id: manager.id, scopes: 'mfa_login_manager') }
  let(:expires_in) { Constants::SHORT_TOKEN_EXPIRES_IN.to_i }
  let(:scope) { 'mfa_login_manager' }
  let(:token) { access_token.token }
  let(:secret_code) { 'aCAQWQWDQASDASD15' }
  let(:sms_code) { '123456' }
  let(:verification_code) { '123456' }
  let(:phone_number) { '+7988445154' }
  let(:default_mfa_params) do
    {
      expires_in: expires_in,
      scope: scope,
      token: token
    }
  end
  let(:request_params) do
    {
      access_token: access_token.token,
      token_type: 'bearer',
      expires_in: access_token.expires_in,
      refresh_token: access_token.refresh_token,
      created_at: access_token.created_at.to_time.to_i,
      scope: access_token.scopes
    }
  end
  let(:params) { ActionController::Parameters.new(request_params) }

  let(:resource_owner) { manager }

  include_examples 'setup trackable', 'manager'

  describe 'POST#create_mfa' do
    subject(:send_request) { post :create_mfa, format: :json, params: request_params }

    let(:authorization_service) { Mfa::UserAuthorizationService }
    let(:params_for_create) do
      params.permit(:email, :password).merge(default_mfa_params.except(:token).merge(model: Manager))
    end

    context 'when params are presented' do
      context 'and params are valid' do
        before do
          allow(authorization_service).to(receive(:perform).with(params_for_create).and_return(token_params))
        end

        it { is_expected.to(have_http_status(:ok)) }

        it_behaves_like 'trackable'
      end

      context 'and email are invalid' do
        let(:email) { 'wrong_email@mail.com' }

        before do
          allow(authorization_service).to(
            receive(:perform).with(params_for_create).and_raise(Errors::InvalidPasswordOrEmail)
          )
        end

        it { is_expected.to have_http_status(:bad_request) }
      end

      context 'and service returned unexpected error' do
        before do
          allow(authorization_service).to(
            receive(:perform).with(params_for_create).and_raise('Something wrong')
          )
        end

        it { is_expected.to have_http_status(:internal_server_error) }
      end
    end
  end

  describe 'GET#app_secret' do
    subject(:send_request) { get :app_secret, format: :json, params: request_params }

    context 'when token has correct scope' do
      it { is_expected.to have_http_status(:ok) }

      it 'returns a secret code for APP' do
        subject
        expect(response.body).to be_a(String)
      end
    end
  end

  describe 'POST#app_verify_and_save' do
    subject(:send_request) { post :app_verify_and_save, format: :json, params: request_params }

    let(:verify_service) { Mfa::VerifyAndSaveNewAppService }
    let(:request_params) { super().merge(verification_code: verification_code, secret_code: secret_code) }
    let(:params_for_verify) do
      params.permit(:secret_code, :verification_code).merge(token: token, generate_token: generate_token)
    end
    let(:generate_token) { true }

    context 'when token has wrong scope' do
      let(:access_token) { create(:access_token, resource_owner_id: manager.id, scopes: 'mfa_login_admin') }

      it { is_expected.to have_http_status(:unauthorized) }
    end

    context 'when token has correct scope' do
      context 'and verification code is correct' do
        before do
          allow(verify_service).to receive(:perform).with(params_for_verify).and_return(token_params)
        end

        it { is_expected.to have_http_status(:ok) }

        it_behaves_like 'trackable'
      end

      context 'and verification code is incorrect' do
        before do
          allow(verify_service).to receive(:perform).with(params_for_verify).and_raise(Errors::InvalidVerificationCode)
        end

        it { is_expected.to have_http_status(:bad_request) }
      end
    end
  end

  describe 'POST#mfa_app_authentication' do
    subject(:send_request) { post :mfa_app_authentication, format: :json, params: request_params }

    let(:app_authentication_service) { Mfa::AppAuthenticationService }
    let(:verification_code) { '333222' }
    let(:request_params) { super().merge(verification_code: verification_code) }
    let(:params_for_app_authentication) { params.permit(:verification_code).merge(token: token) }

    context 'when params are presented' do
      context 'and params are valid' do
        before do
          allow(app_authentication_service).to(
            receive(:perform).with(params_for_app_authentication).and_return(token_params)
          )
        end

        it { is_expected.to have_http_status(:ok) }

        it_behaves_like 'trackable'
      end

      context 'and token in params are invalid' do
        let(:request_params) { { access_token: '' } }
        before do
          allow(app_authentication_service).to(
            receive(:perform).with(params_for_app_authentication).and_raise(Errors::UnknownToken)
          )
        end

        it { is_expected.to have_http_status(:unauthorized) }
      end

      context 'and service returned unexpected error' do
        before do
          allow(app_authentication_service).to(
            receive(:perform).with(params_for_app_authentication).and_raise('Something wrong')
          )
        end

        it { is_expected.to have_http_status(:internal_server_error) }
      end
    end
  end

  describe 'GET#sms_send' do
    subject(:send_request) { get :sms_send, format: :json, params: request_params }

    let(:send_sms_secret_service) { Mfa::SendSmsSecretService }
    let(:request_params) { super().merge(phone_number: phone_number) }
    let(:params_for_sms_send) do
      params.permit(:phone_number).merge(token: token)
    end

    context 'when params are presented' do
      context 'and params are valid' do
        before do
          allow(send_sms_secret_service).to receive(:perform).with(params_for_sms_send).and_return('OK')
        end

        it { is_expected.to have_http_status(:ok) }
      end

      context 'and token in params are invalid' do
        let(:request_params) { { access_token: '' } }

        before do
          allow(send_sms_secret_service).to(
            receive(:perform).with(params_for_sms_send).and_raise(Errors::UnknownToken)
          )
        end

        it { is_expected.to have_http_status(:unauthorized) }
      end

      context 'and service returned unexpected error' do
        before do
          allow(send_sms_secret_service).to(
            receive(:perform).with(params_for_sms_send).and_raise('Something wrong')
          )
        end

        it { is_expected.to have_http_status(:internal_server_error) }
      end
    end
  end

  describe 'POST#sms_verify_and_save' do
    subject(:send_request) { post :sms_verify_and_save, format: :json, params: request_params }

    let(:verify_service) { Mfa::VerifyAndSaveNewPhoneService }
    let(:request_params) { super().merge(phone_number: phone_number, sms_code: sms_code) }
    let(:params_for_sms_verify_and_save) do
      params.permit(:phone_number, :sms_code).merge(token: token, generate_token: generate_token)
    end
    let(:generate_token) { true }

    context 'when token has wrong scope' do
      let(:access_token) { create(:access_token, resource_owner_id: manager.id, scopes: 'mfa_login_admin') }

      it { is_expected.to have_http_status(:unauthorized) }
    end

    context 'when token has correct scope' do
      context 'and sms code is correct' do
        before do
          allow(verify_service).to(
            receive(:perform).with(params_for_sms_verify_and_save).and_return(token_params)
          )
        end

        it { is_expected.to have_http_status(:ok) }

        it_behaves_like 'trackable'
      end

      context 'and sms code is incorrect' do
        before do
          allow(verify_service).to(
            receive(:perform).with(params_for_sms_verify_and_save).and_raise(Errors::InvalidVerificationCode)
          )
        end

        it { is_expected.to have_http_status(:bad_request) }
      end
    end
  end

  describe 'POST#mfa_sms_authentication' do
    subject(:send_request) { post :mfa_sms_authentication, format: :json, params: request_params }

    let(:sms_authentication_service) { Mfa::SmsAuthenticationService }
    let(:sms_code) { '333222' }
    let(:request_params) { super().merge(sms_code: sms_code) }
    let(:params_for_sms_authentication) { params.permit(:sms_code).merge(token: token) }

    context 'when params are presented' do
      context 'and params are valid' do
        before do
          allow(sms_authentication_service).to(
            receive(:perform).with(params_for_sms_authentication).and_return(token_params)
          )
        end

        it { is_expected.to have_http_status(:ok) }

        it_behaves_like 'trackable'
      end

      context 'and token in params are invalid' do
        before do
          allow(sms_authentication_service).to(
            receive(:perform).with(params_for_sms_authentication).and_raise(Errors::UnknownToken)
          )
        end

        it { is_expected.to have_http_status(:internal_server_error) }
      end

      context 'and service returned unexpected error' do
        before do
          allow(sms_authentication_service).to(
            receive(:perform).with(params_for_sms_authentication).and_raise('Something wrong')
          )
        end

        it { is_expected.to have_http_status(:internal_server_error) }
      end
    end
  end

  describe 'GET#mfa_reset_email' do
    subject(:send_request) { get :mfa_reset_email, format: :json, params: request_params }

    let(:send_recovery_email_service) { Mfa::SendRecoveryEmailService }
    let(:params_for_email_send) { params.permit.merge(token: token) }

    context 'when params are presented' do
      context 'and params are valid' do
        before do
          allow(send_recovery_email_service).to receive(:perform).with(params_for_email_send).and_return('OK')
        end

        it { is_expected.to have_http_status(:ok) }
      end

      context 'and token in params are invalid' do
        let(:request_params) { { access_token: '' } }

        before do
          allow(send_recovery_email_service).to(
            receive(:perform).with(params_for_email_send).and_raise(Errors::UnknownToken)
          )
        end

        it { is_expected.to have_http_status(:unauthorized) }
      end

      context 'and service returned unexpected error' do
        before do
          allow(send_recovery_email_service).to(
            receive(:perform).with(params_for_email_send).and_raise('Something wrong')
          )
        end

        it { is_expected.to have_http_status(:internal_server_error) }
      end
    end
  end

  describe 'POST#mfa_reset' do
    subject(:send_request) { post :mfa_reset, format: :json, params: request_params }

    let(:request_params) { { token: token, code: verification_code, email: email, password: password } }
    let(:reset_service) { Mfa::ResetService }
    let(:params_for_reset) { params.permit(:token, :code, :email, :password) }

    context 'when params are presented' do
      context 'and params are valid' do
        before do
          allow(reset_service).to receive(:perform).with(params_for_reset).and_return('OK')
        end

        it { is_expected.to have_http_status(:ok) }
      end

      context 'and token in params are invalid' do
        let(:request_params) { { access_token: '' } }

        before do
          allow(reset_service).to(
            receive(:perform).with(params_for_reset).and_raise(Errors::InvalidMfaRecoveryParams)
          )
        end

        it { is_expected.to have_http_status(:bad_request) }
      end

      context 'and service returned unexpected error' do
        before do
          allow(reset_service).to(
            receive(:perform).with(params_for_reset).and_raise('Something wrong')
          )
        end

        it { is_expected.to have_http_status(:internal_server_error) }
      end
    end
  end
end
