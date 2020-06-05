# frozen_string_literal: true

module Mfa
  class SmsSenderService < ApplicationService
    # @attr_reader params [Hash]
    # - :phone_number [String] To phone number
    # - :message [String] Message to send

    include Errors::Logger

    include_rails_config :twilio_phone_number

    def call
      message = client.messages.create(
        from: twilio_phone_number,
        to: param_phone_number.to_s,
        body: body_message
      )
      log_info("#{self.class.name}.call: #{message.fetch.inspect}")
    rescue Twilio::REST::RestError => e
      log_error(e)
      raise e
    end

    private

    def client
      Twilio::REST::Client.new
    end

    def body_message
      "#{auth_sms_text} #{param_message}"
    end

    def auth_sms_text
      I18n.t('common.auth_sms_text')
    end

    def param_phone_number
      params[:phone_number]
    end

    def param_message
      params[:message]
    end
  end
end
