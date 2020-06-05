# frozen_string_literal: true

module Api
  module V1
    class AuthController < Doorkeeper::TokensController
      include Api::Concerns::Trackable
      include Api::Concerns::CommonParams
      include Api::Concerns::SetNoCacheHeaders
      include Errors::ControllerHandlers

      before_action :authorize!, only: %i[
        app_verify_and_save
        mfa_app_authentication
        sms_send
        sms_verify_and_save
        mfa_sms_authentication
        mfa_reset_email
      ]

      api :POST, '/management/auth/token', 'Go to the next step MFA for manager by email and password'
      param :email, :email, desc: 'Manager`s email'
      param :password, String, desc: 'Manager`s password'
      returns :auth_response, code: 200, desc: 'Auth token and MFA params'
      error code: 401, desc: 'Invalid manager credentials'
      error code: 400, desc: 'Bad request'
      def create_mfa
        render_response(
          Mfa::UserAuthorizationService.perform(
            params.permit(:email, :password).merge(default_mfa_params.except(:token).merge(model: Manager))
          )
        )
      end

      api :GET, '/management/auth/app_secret', 'Receive totp secret code for registration APP'
      returns code: 200, desc: 'Secret code for registration' do
        property :secret_code, String, desc: 'Secret code for registration APP'
      end
      error code: 401, desc: 'Invalid manager credentials or refresh token'
      error code: 400, desc: 'Bad request'
      def app_secret
        render_response(secret_code: ROTP::Base32.random)
      end

      api :POST, '/management/auth/app_verify_and_save', 'Verify verification code and register APP'
      param :secret_code, String, required: true, desc: 'Secret code generated on previous step'
      param :verification_code, String, required: true, desc: 'Verification code from user`s APP'
      returns :auth_token_params, code: 200, desc: 'Manager`s auth token params'
      error code: 401, desc: 'Invalid manager credentials or refresh token'
      error code: 400, desc: 'Bad request'
      def app_verify_and_save
        render_response(
          Mfa::VerifyAndSaveNewAppService.perform(
            params.permit(:secret_code, :verification_code)
                  .merge(token: doorkeeper_token.token, generate_token: true)
          )
        )
      end

      api :POST, '/management/auth/mfa_app_authentication', 'MFA authorization through APP'
      param :verification_code, String, required: true, desc: 'Verification code'
      returns :auth_token_params, code: 200, desc: 'Manager`s auth token params'
      error code: 400, desc: 'Bad request'
      def mfa_app_authentication
        render_response(
          Mfa::AppAuthenticationService.perform(
            params.permit(:verification_code).merge(token: doorkeeper_token.token)
          )
        )
      end

      api :GET, '/management/auth/sms_send', 'Send SMS to entered phone'
      param :phone_number, :phone, required: true, desc: 'Phone number by user'
      returns code: 200, desc: 'Sms successfully sent'
      error code: 401, desc: 'Invalid manager credentials or refresh token'
      error code: 400, desc: 'Bad request'
      def sms_send
        render_response(
          Mfa::SendSmsSecretService.perform(
            params.permit(:phone_number).merge(token: doorkeeper_token.token)
          )
        )
      end

      api :POST, '/management/auth/sms_verify_and_save', 'Verify sms code and save phone number'
      param :sms_code, String, required: true, desc: 'Code from sms'
      param :phone_number, :phone, required: true, desc: 'Phone number by user'
      returns :auth_token_params, code: 200, desc: 'Manager`s auth token params'
      error code: 401, desc: 'Invalid manager credentials or refresh token'
      error code: 400, desc: 'Bad request'
      def sms_verify_and_save
        render_response(
          Mfa::VerifyAndSaveNewPhoneService.perform(
            params.permit(:phone_number, :sms_code)
                  .merge(token: doorkeeper_token.token, generate_token: true)
          )
        )
      end

      api :POST, '/management/auth/mfa_sms_authentication', 'MFA authorization through SMS'
      param :sms_code, String, required: true, desc: 'Code from sms'
      returns :auth_token_params, code: 200, desc: 'Manager`s auth token params'
      error code: 400, desc: 'Bad request'
      def mfa_sms_authentication
        render_response(
          Mfa::SmsAuthenticationService.perform(
            params.permit(:sms_code).merge(token: doorkeeper_token.token)
          )
        )
      end

      api :GET, '/management/auth/mfa_reset_email', 'Send email(s) to owner or superadmin and user'
      returns code: 200, desc: 'Email successfully sent'
      error code: 401, desc: 'Invalid manager credentials or refresh token'
      error code: 400, desc: 'Bad request'
      def mfa_reset_email
        render_response(
          Mfa::SendRecoveryEmailService.perform(params.permit.merge(token: doorkeeper_token.token))
        )
      end

      api :POST, '/management/auth/mfa_reset', 'Verificate recovery code and reset MFA method'
      param :token, String, required: true, desc: 'Token from manager`s email'
      param :email, :email, required: true, desc: 'Manager`s email'
      param :password, String, required: true, desc: 'Manager`s password'
      param :code, String, required: true, desc: '6 digits recovery code'
      returns :auth_token_params, code: 200, desc: 'Manager`s `mfa_login` auth token params'
      error code: 400, desc: 'Bad request cos of exeption in service'
      def mfa_reset
        render_response(
          Mfa::ResetService.perform(params.permit(:token, :code, :email, :password))
        )
      end

      api :POST, '/management/auth/revoke', 'Revoke access token'
      param :token, String, required: true, desc: 'Access or refresh token'
      def revoke
        super
      end

      api :POST, '/management/auth/refresh_impersonate_token', 'Refreshes impersonate session token'
      param :refresh_token, String, required: true, desc: 'Refresh token'
      returns :auth_token_params, code: 200, desc: 'Impersonate session`s auth token params'
      error code: 401, desc: 'Invalid refresh token'
      error code: 400, desc: 'Bad request'
      def refresh_impersonate_token
        create
      end

      api :POST, '/management/auth/refresh_access_token', 'Refreshes access token'
      param :refresh_token, String, required: true, desc: 'Refresh token'
      returns :auth_token_params, code: 200, desc: 'Manager session`s auth token params'
      error code: 401, desc: 'Invalid refresh token'
      error code: 400, desc: 'Bad request'
      def refresh_access_token
        create
      end

      private

      def set_response_headers
        response.headers['X-Content-Type-Options'] = 'nosniff'
      end

      def render_response(data = {}, http_code = 200)
        render json: data, status: http_code
      end

      def authorize!
        doorkeeper_authorize! :mfa_login_manager
      end

      def default_mfa_params
        {
          expires_in: Constants::SHORT_TOKEN_EXPIRES_IN,
          scope: 'mfa_login_manager',
          token: doorkeeper_token&.token
        }
      end

      # Required for Devise `Trackable` feature
      def resource_owner_class
        Manager
      end
    end
  end
end
