# frozen_string_literal: true

module Mfa
  class VerifyAndSaveNewPhoneService < ApplicationService
    include Concerns::UserFinder
    include Concerns::PhoneNumberFormatter
    # @attr_reader params [Hash]
    # - sms_code: [String] Code from SMS
    # - phone_number: [String] Phone number by User
    # - generate_token: [Boolean] Generate token or not

    def call
      raise Errors::InvalidVerificationCode unless sms_code_valid?

      update_user_profile
      generate_access_token if param_generate_token
    end

    private

    def user
      @user ||= find_user_by_token
    end

    def sms_code_valid?
      param_sms_code.eql? user.sms_secret
    end

    def generate_access_token
      Security::GenerateTokenService.perform(user: user, scope: user.class.to_s.downcase)
    end

    def update_user_profile
      user.assign_attributes(totp_secret_encrypted: nil) if user.mfa_method == 'application'
      user.assign_attributes(mfa_phone: param_phone_number, mfa_method: :phone_number)
      user.assign_attributes(sms_secret_encrypted: nil, sms_secret_created_at: nil)
      user.save!
    end

    def param_sms_code
      params[:sms_code]
    end

    def param_phone_number
      parse_phone_number(params[:phone_number]).e164_number.to_s
    end

    def param_generate_token
      params[:generate_token]
    end
  end
end
