# frozen_string_literal: true

module Masterclasses
  class FindListService < BaseService
    include Concerns::MasterclassListQuery
    include Api::Concerns::Pagination

    option :featured, optional: true
    option :title, optional: true
    option :page, optional: true, type: ->(value) { value.to_i }
    option :per_page, optional: true, type: ->(value) { value.to_i }
    option :order_by, default: -> { :desc }
    option :limit, optional: true, type: ->(value) { value.to_i }

    def call
      @per_page = limit if limit
      data = pagination(masterclasses, page, per_page)
      data = data.map { |masterclass| yield(masterclass) } if block_given?
      {
        data: data,
        total: masterclasses.length
      }
    end
  end
end
