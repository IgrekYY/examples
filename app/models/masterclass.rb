# frozen_string_literal: true

class Masterclass < ApplicationRecord
  include PgSearch::Model

  include Concerns::Imageable
  include Concerns::HeroImageable
  include Concerns::Watchable
  include Concerns::NewSlugged

  acts_as_paranoid

  has_many :masterclasses_rewards, dependent: :destroy
  has_many :rewards, through: :masterclasses_rewards
  has_many :quizzes, dependent: :destroy
  has_many :masterclasses_entities, dependent: :destroy
  has_many :recipes, through: :masterclasses_entities, source: :entity, source_type: 'Recipe'
  has_many :blog_posts, through: :masterclasses_entities, source: :entity, source_type: 'BlogPost'
  has_many :masterclass_monitorings, dependent: :destroy
  has_many :users_masterclasses, dependent: :destroy
  has_many :users, through: :users_masterclasses
  has_many :masterclasses_tutorials, dependent: :destroy
  has_many :tutorials, through: :masterclasses_tutorials
  has_many :authors_klasses, foreign_key: 'klass_id', dependent: :destroy
  has_many :authors, through: :authors_klasses

  validates :validations

  pg_search_scope :search_by_title, against: :title,
                                    using: { tsearch: { normalization: 6,
                                                        dictionary: 'english' } }

  def current_user_monitoring(current_user)
    return unless current_user

    MasterclassMonitorings::Show.call(self, current_user)
  end

  private

  def presenter_class
    MasterclassPresenter
  end
end
