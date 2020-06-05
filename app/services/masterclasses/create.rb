# frozen_string_literal: true

require 'dry/monads/do'

module Masterclasses
  class Create < BaseService
    include Dry::Monads[:result, :list, :try]
    include Dry::Monads::Do.for(:call)

    option :masterclass_params, {} do
      option :title
      option :short_description
      option :long_description
      option :trailer_video_uid, optional: true
      option :recipe_ids, [proc(&:to_i)], optional: true
      option :blog_post_ids, [proc(&:to_i)], optional: true
    end
    option :picture_ids, [proc(&:to_i)]
    option :quiz_ids, [proc(&:to_i)], optional: true
    option :reward_ids, [proc(&:to_i)], optional: true
    option :tutorial_ids, [proc(&:to_i)]
    option :user, default: -> { nil }
    option :author_ids, [proc(&:to_i)]

    option :masterclass_repo, default: -> { Masterclass }

    def call
      [masterclass_params, tutorial_ids, author_ids].each { |m| yield validate_params(m) }
      @masterclass = yield build
      yield add_pictures

      masterclass_repo.transaction do
        yield save
        yield update_quizzes if quiz_ids
        yield link_author
        yield link_reward if reward_ids
        yield link_tutorial
      end
      yield update_slug
      Success(masterclass)
    end

    private

    attr_reader :masterclass

    def build
      Success(masterclass_repo.new(masterclass_params.to_h))
    end

    def add_pictures
      Try { masterclass.add_pictures(picture_ids, user) }
    end

    def save
      Try { masterclass.save! }
    end

    def update_slug
      Try { masterclass.update!(slug: GenerateSlug.call(masterclass)) }
    end

    def update_quizzes
      List(quiz_ids).fmap do |id|
        Try { Quiz.find(id).update!(masterclass_id: masterclass.id) }
      end.typed(Dry::Monads::Try).traverse
    end

    def link_reward
      List(reward_ids).fmap do |id|
        Try { MasterclassesReward.create!(masterclass_id: masterclass.id, reward_id: id) }
      end.typed(Dry::Monads::Try).traverse
    end

    def link_tutorial
      List(tutorial_ids).fmap do |id|
        Try { MasterclassesTutorial.create!(masterclass_id: masterclass.id, tutorial_id: id) }
      end.typed(Dry::Monads::Try).traverse
    end

    def link_author
      List(author_ids).fmap do |id|
        Try { AuthorsKlass.create!(klass_id: masterclass.id, author_id: id) }
      end.typed(Dry::Monads::Try).traverse
    end

    def validate_params(param)
      return Success(param) if param.present?

      Failure(:params_are_missing)
    end
  end
end
