# frozen_string_literal: true

module Mfa
  class AppAuthenticationService < ApplicationService
    include Concerns::UserFinder
    include Login::CheckAttempts
    include Login::AttemptsCounter
    # @attr_reader params [Hash]
    # - verification_code: [String] method of MFA
    # - token: [String] Login token for User

    def call
      raise Errors::UserTemporaryBlocked if user_blocked?

      authentication_failed! unless verification_code_valid?

      reset_attempts_counter
      generate_access_token
    end

    private

    def user
      @user ||= find_user_by_token
    end

    def verification_code_valid?
      check = ROTP::TOTP.new(user&.totp_secret).verify(param_verification_code.to_s)
      check.present?
    end

    def authentication_failed!
      incr_failed_attempts_counter
      raise Errors::InvalidVerificationCode
    end

    def generate_access_token
      Security::GenerateTokenService.perform(user: user, scope: user.class.to_s.downcase)
    end

    def param_verification_code
      params[:verification_code]
    end
  end
end
