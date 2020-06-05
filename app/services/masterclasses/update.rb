# frozen_string_literal: true

require 'dry/monads/do'

module Masterclasses
  class Update < BaseService
    include Dry::Monads[:result, :list, :try]
    include Dry::Monads::Do.for(:call)

    option :masterclass
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
    option :user, optional: true
    option :author_ids, [proc(&:to_i)]

    def call
      [masterclass_params, tutorial_ids, author_ids].each { |m| yield validate_params(m) }
      Masterclass.transaction do
        yield update_masterclass
        yield add_pictures
        yield update_quizzes if quiz_ids
        yield link_author if authors_changed?
        yield link_tutorial if tutorials_changed?
        yield link_reward if reward_ids && rewards_changed?
      end
      Success(masterclass)
    end

    private

    def update_masterclass
      Try do
        masterclass.assign_attributes(masterclass_params.to_h)
        masterclass.assign_attributes(slug: GenerateSlug.call(masterclass)) if masterclass.title_changed?
        masterclass.save!
      end
    end

    def add_pictures
      Try { masterclass.add_pictures(picture_ids, user) }
    end

    def update_quizzes
      List(quiz_ids).fmap do |id|
        Try { Quiz.find(id).update!(masterclass_id: masterclass.id) }
      end.typed(Dry::Monads::Try).traverse
    end

    def link_reward
      List(reward_ids - masterclass.rewards.ids).fmap do |id|
        Try { masterclasses_reward_repo.create!(masterclass_id: masterclass.id, reward_id: id) }
      end.typed(Dry::Monads::Try).traverse
    end

    def link_tutorial
      List(tutorial_ids - masterclass.tutorials.ids).fmap do |id|
        Try { MasterclassesTutorial.create!(masterclass_id: masterclass.id, tutorial_id: id) }
      end.typed(Dry::Monads::Try).traverse
    end

    def link_author
      List(author_ids - masterclass.authors.ids).fmap do |id|
        Try { AuthorsKlass.create!(klass_id: masterclass.id, author_id: id) }
      end.typed(Dry::Monads::Try).traverse
    end

    def tutorials_changed?
      masterclass.tutorials.ids.sort != tutorial_ids.sort
    end

    def rewards_changed?
      masterclass.rewards.ids.sort != reward_ids.sort
    end

    def authors_changed?
      masterclass.authors.ids.sort != author_ids.sort
    end  

    def validate_params(param)
      return Success(param) if param.present?

      Failure(:params_are_missing)
    end

    def masterclasses_reward_repo
      MasterclassesReward
    end
  end
end
