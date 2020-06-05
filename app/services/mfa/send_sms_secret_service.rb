# frozen_string_literal: true

module Mfa
  class SendSmsSecretService < ApplicationService
    include Concerns::UserFinder
    include Concerns::PhoneNumberFormatter
    # @attr_reader params [Hash]
    # - token: [String] Login token for User
    # - phone_number: [String] Phone number from User

    def call
      generate_sms_code
      send_sms_code
      { sucsess: true }
    end

    private

    def user
      @user ||= find_user_by_token
    end

    def generate_sms_code
      Mfa::GenerateSmsCodeService.perform(user: user)
    end

    def send_sms_code
      Mfa::SmsSenderService.perform(phone_number: param_phone_number, message: user.sms_secret)
    end

    def param_phone_number
      parse_phone_number(params[:phone_number]).e164_number.to_s
    end
  end
end
