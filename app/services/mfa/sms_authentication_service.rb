# frozen_string_literal: true

module Mfa
  class SmsAuthenticationService < ApplicationService
    include Concerns::UserFinder
    include Login::CheckAttempts
    include Login::AttemptsCounter
    # @attr_reader params [Hash]
    # - sms_code: [String] Code from SMS
    # - token: [String] Login token for User

    def call
      raise Errors::UserTemporaryBlocked if user_blocked?

      authentication_failed! unless sms_code_valid?

      reset_attempts_counter
      remove_sms_code_from_user
      generate_access_token
    end

    private

    def user
      @user ||= find_user_by_token
    end

    def sms_code_valid?
      param_sms_code.eql? user.sms_secret
    end

    def authentication_failed!
      incr_failed_attempts_counter
      raise Errors::InvalidVerificationCode
    end

    def generate_access_token
      Security::GenerateTokenService.perform(user: user, scope: user.class.to_s.downcase)
    end

    def remove_sms_code_from_user
      user.sms_secret_encrypted = nil
      user.sms_secret_created_at = nil
      user.save!
    end

    def param_sms_code
      params[:sms_code]
    end
  end
end
