# frozen_string_literal: true

module Errors
  module Presenters
    class Unauthorized < Errors::AbstractPresenter
      EXCEPTIONS = %w[Doorkeeper::Errors::InvalidToken
                      Doorkeeper::Errors::TokenForbidden
                      Doorkeeper::Errors::TokenExpired
                      Doorkeeper::Errors::TokenRevoked
                      Doorkeeper::Errors::TokenUnknown
                      Errors::NotAuthorized
                      Errors::EmptyAuthInfoOrEmail].freeze
    end
  end
end
