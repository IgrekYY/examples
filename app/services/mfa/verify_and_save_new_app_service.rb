# frozen_string_literal: true

module Mfa
  class VerifyAndSaveNewAppService < ApplicationService
    include Concerns::UserFinder
    # @attr_reader params [Hash]
    # - secret_code: [String] Secret code from user
    # - verification_code: [String] Verification code from user
    # - generate_token: [Boolean] Generate token or not

    def call
      raise Errors::InvalidVerificationCode unless verification_code_valid?

      update_user_profile
      generate_access_token if param_generate_token
    end

    private

    def user
      @user ||= find_user_by_token
    end

    def verification_code_valid?
      check = ROTP::TOTP.new(param_secret_code).verify(param_verification_code.to_s)
      check.present?
    end

    def generate_access_token
      Security::GenerateTokenService.perform(user: user, scope: user.class.to_s.downcase)
    end

    def update_user_profile
      user.assign_attributes(mfa_phone: nil) if user.mfa_method == 'phone_number'
      user.assign_attributes(totp_secret: param_secret_code, mfa_method: :application)
      user.save!
    end

    def param_verification_code
      params[:verification_code]
    end

    def param_secret_code
      params[:secret_code]
    end

    def param_generate_token
      params[:generate_token]
    end
  end
end
