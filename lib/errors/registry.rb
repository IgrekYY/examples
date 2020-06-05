# frozen_string_literal: true

module Errors
  class Registry
    attr_reader :presenters, :exceptions

    def initialize(presenters)
      build_presenters(presenters)
      build_exceptions
    end

    private

    def presenter_class_by_error(error)
      exceptions[error.class.to_s]
    end

    def build_presenters(presenters)
      @presenters = presenters.map { |class_name| "Errors::Presenters::#{class_name}".constantize }
    end

    def build_exceptions
      @exceptions = presenters.each_with_object({}) do |presenter, res|
        presenter::EXCEPTIONS.each do |class_name|
          exception = class_name.constantize
          res[exception] = presenter
        end
      end
    end
  end
end
