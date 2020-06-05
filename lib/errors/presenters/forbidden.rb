# frozen_string_literal: true

module Errors
  module Presenters
    class Forbidden < Errors::AbstractPresenter
      EXCEPTIONS = %w[Pundit::NotAuthorizedError
                      Errors::AccessDenied].freeze
    end
  end
end
