# frozen_string_literal: true

module Mfa
  class ResetService < ApplicationService
    include Login::CheckAttempts
    include Login::AttemptsCounter
    # @attr_reader params [Hash]
    # - password: [String] User's password
    # - email: [String] user's email
    # - code: [String] Recovery code from user
    # - token: [String] Login token for User

    def call
      raise Errors::UserTemporaryBlocked if user_blocked?

      validate_recovery_params!
      validate_code!
      validate_credentials!

      reset_attempts_counter
      update_recovery_params
      update_user_profile
      generate_access_token.except(:refresh_token)
    rescue Errors::FailedCheckRecoveryParams, Errors::UnknownUser => e
      log_error(e)
      incr_failed_attempts_counter
      raise Errors::InvalidMfaRecoveryParams
    end

    private

    def user
      @user ||= find_user_by_token!
    end

    def user_recovery_params
      @user_recovery_params ||= user.mfa_recoveries.last
    end

    def find_user_by_token!
      user_mfa_recovery_params = MfaRecovery.find_by(token: param_token)
      raise Errors::UnknownResetMfaToken if user_mfa_recovery_params.nil?

      user = user_mfa_recovery_params.record_owner
      raise Errors::UnknownUser if user.nil?

      user
    end

    def validate_recovery_params!
      raise Errors::ExpiredRecoveryParams if user_recovery_params.expires_at < Time.now
      raise Errors::RecoveryParamsAlreadyUsed if user_recovery_params.applied_at
    end

    def validate_code!
      raise Errors::InvalidMfaRecoveryCode unless param_code.to_s == user_recovery_params.code.to_s
    end

    def validate_credentials!
      checked_user = user.class.authenticate(param_email, param_password)
      raise Errors::UnknownUser unless user == checked_user
    end

    def update_recovery_params
      user_recovery_params.update(applied_at: Time.now)
    end

    def update_user_profile
      user.assign_attributes(in_mfa_recovery_process: false)
      user.assign_attributes(mfa_phone: nil) if user.mfa_method == 'phone_number'
      user.assign_attributes(totp_secret_encrypted: nil) if user.mfa_method == 'application'
      user.assign_attributes(mfa_method: nil)
      user.save!
    end

    def generate_access_token
      Security::GenerateTokenService.perform(
        user: user,
        scope: "mfa_login_#{user.class.to_s.downcase}",
        expires_in: Constants::SHORT_TOKEN_EXPIRES_IN
      )
    end

    def param_code
      params[:code]
    end

    def param_token
      params[:token]
    end

    def param_email
      params[:email]
    end

    def param_password
      params[:password]
    end
  end
end
