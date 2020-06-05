# frozen_string_literal: true

module Errors
  module Presenters
    class NotFound < Errors::AbstractPresenter
      EXCEPTIONS = %w[Errors::RecordNotFound].freeze
    end
  end
end
