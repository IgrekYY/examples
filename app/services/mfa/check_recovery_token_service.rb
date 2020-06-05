# frozen_string_literal: true

module Mfa
  class CheckRecoveryTokenService < ApplicationService
    # @attr_reader params [Hash]
    # - :token [String] Admin or Manager

    def call
      validate_params!
    end

    private

    def user
      @user ||= find_user_by_token!
    end

    def user_recovery_token
      @user_recovery_token ||= user.mfa_recoveries.last
    end

    def find_user_by_token!
      user_recovery_params = MfaRecovery.find_by(token: param_token)
      raise Errors::UnknownResetMfaToken if user_recovery_params.nil?

      user = user_recovery_params.record_owner
      raise Errors::UnknownUser if user.nil?

      user
    end

    def validate_params!
      raise Errors::ExpiredRecoveryParams if user_recovery_token.expires_at < Time.now
      raise Errors::RecoveryParamsAlreadyUsed if user_recovery_token.applied_at
    end

    def param_token
      params[:token]
    end
  end
end
