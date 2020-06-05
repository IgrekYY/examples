# frozen_string_literal: true

require 'dry/monads/do'

module Collections
  class Create < BaseService
    include Dry::Monads[:result, :try, :list]
    include Dry::Monads::Do.for(:call)

    option :user
    option :collection_attributes
    option :state_params, default: -> {}

    option :repo, default: -> { user.collections }

    def call
      @collection = yield build
      yield validate
      yield add_pictures if collection_attributes[:picture_ids].present?

      repo.transaction do
        yield save
        yield attach_recipes
        yield change_state
      end

      Success(collection)
    end

    private

    attr_reader :collection

    def build
      attributes = collection_attributes.slice(*repo.column_names)
      Success(repo.new(attributes))
    end

    #TODO: Replace with dry validation
    def validate
      Try { collection.validate! }
    end

    def add_pictures
      Try { collection.add_pictures(collection_attributes[:picture_ids]) }
    end

    def save
      Try { collection.save! }
    end

    def attach_recipes
      List(collection_attributes[:recipe_ids]).fmap do |recipe_id|
        Collections::PushEntity.call(
          user: user,
          collection_id: collection.id,
          entity_id: recipe_id,
          entities_repo: Recipe
        ).to_result
      end.typed(Dry::Monads::Result).traverse
    end

    def change_state
      Try { collection.change_state(user, state_params) }
    end

  end
end
