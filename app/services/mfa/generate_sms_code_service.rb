# frozen_string_literal: true

module Mfa
  class GenerateSmsCodeService < ApplicationService
    # @attr_reader params [Hash]
    # - :user [User] Admin or Manager

    def call
      generate_sms_secret
    end

    private

    def user
      params[:user]
    end

    def generate_sms_secret
      user.sms_secret = rand.to_s[2..7]
      user.sms_secret_created_at = Time.now
      user.save!
    end
  end
end
