# frozen_string_literal: true

module Errors
  module Presenters
    class BadRequest < Errors::AbstractPresenter
      EXCEPTIONS = %w[
        Apipie::ParamMissing
        Apipie::UnknownParam
        Apipie::ParamInvalid
        ActionController::ParameterMissing
        Errors::UnknownUser
        Errors::EmailСonfirmation
        Errors::UnknownResetPasswordToken
        Errors::UserAlreadyInMasterclass
      ].freeze

      def error_code
        case error
        when Apipie::ParamMissing
          :parameter_missing
        when Apipie::UnknownParam
          :parameter_unknown
        when Apipie::ParamInvalid
          :parameter_invalid
        else
          super
        end
      end

      def response_data_apipie_param_missing
        { param: apipie_param_name }
      end

      def response_data_apipie_unknown_param
        { param: apipie_param_name }
      end

      def response_data_apipie_param_invalid
        { param: apipie_param_name, value: error.value, error: error.error }
      end

      def response_data_action_controller_parameter_missing
        { param: error.param.to_s }
      end

      def response_data_stripe_invalid_request_error
        { param: error.param.to_s }
      end

      private

      def apipie_param_name
        error.param.respond_to?(:name) ? error.param.name : error.param.to_s
      end
    end
  end
end
