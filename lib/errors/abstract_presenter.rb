# frozen_string_literal: true

module Errors
  class AbstractPresenter
    EXCEPTIONS = [].freeze # define_this_value

    def initialize(error)
      @error = error
    end

    def build_response
      { code: error_code, message: response_message, data: response_data }
    end

    def error_code
      case error.class.to_s
      when 'StandardError'
        :unexpected_error
      else
        error.class.to_s.split('::').last.underscore.to_sym
      end
    end

    def http_status
      case self.class.to_s
      when 'Errors::Presenters::UnexpectedError'
        :internal_server_error
      else
        self.class.to_s.split('::').last.underscore.to_sym
      end
    end

    protected

    attr_reader :error

    def handeled_exceptions
      self.class::EXCEPTIONS
    end

    def response_message
      respond_to?(response_message_handler) ? send(response_message_handler) : error.message
    end

    def response_data
      result = respond_to?(response_data_hendler) ? send(response_data_hendler) : {}
      result.merge!(extended_response_data) if %w[preproduction production].exclude?(Rails.env)
      result
    end

    def response_data_hendler
      @response_data_hendler ||= 'response_data_' + error_class_underscore
    end

    def response_message_handler
      @response_message_handler ||= 'response_message_' + error_class_underscore
    end

    def extended_response_data
      { exception: error.class.name, message: error.message, backtrace: error.backtrace }
    end

    def error_class_underscore
      error.class.to_s.underscore.gsub(/\W+/, '_')
    end
  end
end
