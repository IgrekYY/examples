# frozen_string_literal: true

module Mfa
  class UserAuthorizationService < ApplicationService
    include Concerns::PhoneNumberFormatter
    include Login::CheckAttempts
    include Login::AttemptsCounter
    # @attr_reader params [Hash]
    # - model: [Model] Manager or Admin
    # - password: [String] User's password
    # - expires_in: [Ineger] Lifetime of token
    # - scope: [String] Scope for user
    # - email: [String] user's email

    include_rails_config :mfa_procedure_enabled

    def call
      raise Errors::UserTemporaryBlocked if user_blocked?

      reset_attempts_counter if user
      return generate_access_token unless mfa_procedure_enabled

      generate_access_token(param_scope, param_expires_in).except(:refresh_token).merge(merge_params)
    end

    private

    def generate_access_token(scope = nil, expires_in = nil)
      Security::GenerateTokenService.perform(
        user: user,
        scope: scope || user.class.to_s.downcase,
        expires_in: expires_in
      )
    end

    def user
      @user ||= find_user
    end

    def find_user
      user = param_model.authenticate(param_email, param_password)
      login_failed! if user.nil?

      user
    end

    def login_failed!
      incr_failed_attempts_counter
      raise Errors::InvalidPasswordOrEmail
    end

    def merge_params
      return recovery_params unless user.mfa_method == 'phone_number'

      recovery_params.merge(phone_number: parse_phone_number(user.mfa_phone).international_number)
    end

    def recovery_params
      standart_params.merge(
        is_in_mfa_recovery_process: user.in_mfa_recovery_process?,
        is_mfa_recovery_params_expired: user.in_mfa_recovery_process? ? user_mfa_recovery_params_expired? : false
      )
    end

    def standart_params
      { is_a_root: user.role == 'root', mfa_method: user.mfa_method }
    end

    def user_mfa_recovery_params_expired?
      user_recovery_params = user.mfa_recoveries.last
      return false if user_recovery_params.nil?

      user_recovery_params.applied_at.present? ? false : user_recovery_params.expires_at < Time.now
    end

    def param_scope
      params[:scope]
    end

    def param_expires_in
      params[:expires_in]
    end

    def param_email
      params[:email]
    end

    def param_password
      params[:password]
    end

    def param_model
      params[:model]
    end
  end
end
