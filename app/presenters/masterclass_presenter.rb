# frozen_string_literal: true

class MasterclassPresenter < ApplicationPresenter
  MODEL_ATTRIBUTES = %i[id param].freeze
  ASSOCIATIONS = %i[associations].freeze

  delegate(*MODEL_ATTRIBUTES, to: :record)
  delegate(*ASSOCIATIONS, to: :record)

  def masterclass_detailed_page_context(current_user = nil)
    properties
      .merge(associations: association_presenter)
  end

  private

  def association_presenter(present_method: :method)
    return unless associations

    associations.map { |author| author.present(nil).public_send(method) }
  end

  def properties
    record_attributes.slice(*MODEL_ATTRIBUTES)
  end

  def record_attributes
    record.attributes.symbolize_keys
  end
end
