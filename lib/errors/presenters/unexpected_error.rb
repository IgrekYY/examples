# frozen_string_literal: true

module Errors
  module Presenters
    class UnexpectedError < Errors::AbstractPresenter
      EXCEPTIONS = %w[StandardError].freeze
    end
  end
end
