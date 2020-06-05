# frozen_string_literal: true

module Api
  class ApplicationController < ActionController::API
    include Errors::ControllerHandlers
    include Dry::Monads[:result]

    before_action :doorkeeper_authorize!

    private

    def current_resource_owner
      raise ActionController::ParameterMissing, 'Missing access token' if doorkeeper_token.blank?

      User.find(doorkeeper_token.resource_owner_id)
    end

    alias_method 'current_user', 'current_resource_owner'

    def render_response(data = {}, http_code = 200)
      render json: data, status: http_code
    end

    def render_monad_response(data = {}, http_code = 200)
      case data = data.to_result
      when Success
        render json: data.value!, status: http_code
      when Failure
        render json: { errors: data.failure }, status: 422
      else
        head 500
      end
    end
  end
end
