# frozen_string_literal: true

module Api
  module Concerns
    module CommonParams # rubocop:disable Metrics/ModuleLength
      extend ActiveSupport::Concern

      included do # rubocop:disable Metrics/BlockLength
        def_param_group :pagination do
          param :page, :number, required: false, desc: 'Sets the page pagination option'
          param :per_page, :number, required: false, desc: 'Set the per page pagination option'
        end

        def_param_group :assertion_auth_params do
          param :assertion, Hash, required: true, desc: 'Auhtenticate params' do
            param :access_token, String, required: true, desc: 'Access token for auth'
            param :uid, String, required: true, desc: 'uID for auth, required for Apple login'
            param :first_name, String, required: false, desc: 'First name, required for FIRST Apple login'
            param :last_name, String, required: false, desc: 'Last name, required for FIRST Apple login'
          end
        end

        def_param_group :auth_token_params do
          property :access_token, String, desc: 'User access token'
          property :refresh_token, String, required: false, desc: 'User refresh token'
          property :token_type, String, desc: 'Type of the access token'
          property :expires_in, Integer, desc: 'TTL of access token'
          property :created_at, Integer, desc: 'Unix timestamp when token has been generated'
          # property :scope, String, desc: 'Authorization scope'
        end

        def_param_group :user_params_create do
          param :user, Hash, desc: 'User params' do
            param :first_name, String, required: true, desc: 'User first name'
            param :last_name, String, required: true, desc: 'User last name'
            param :username, String, desc: 'User username'
            param :email, String, required: true, desc: 'User email'
            param :password, String, required: true, desc: 'User password'
            param :password_confirmation, String, desc: 'Confirmation password'
            param :location, String, desc: 'User location'
            param :description, String, desc: 'User`s description'
            param :html_description, String, desc: 'User`s story description'
            param :site, String, desc: 'User site'
          end
        end

        def_param_group :user_params_update do
          param :user, Hash, desc: 'User params' do
            param :first_name, String, desc: 'User first name'
            param :last_name, String, desc: 'User last name'
            param :username, String, desc: 'User username'
            param :location, String, desc: 'User location'
            param :description, String, desc: 'User`s description'
            param :html_description, String, desc: 'User`s story description'
            param :site, String, desc: 'User site'
            param :picture, String, desc: 'User picture'
            param :twitter_link, String, desc: 'User twitter link'
            param :pinterest_link, String, desc: 'User pinterest link'
            param :instagram_link, String, desc: 'User instagram link'
            param :blog_title, String, desc: 'User title of blog'
            param :use_blog_as_user_name, :boolean, desc: 'User instagram link'
            param :business_name, String, desc: 'Business name(only business account)'
          end
        end

        def_param_group :shopping_list_item_params do
          param :shopping_list_item, Hash, required: true, desc: 'Shopping list item params' do
            param :servings, :number, desc: 'Number of servings'
            param :recipe_id, :number, desc: 'Recipe ID'
            param :recipe_ingredient_id, :number, desc: 'Recipe ingredient ID'
            param :text, String, desc: 'Name of shopping item'
            param :checked, :boolean, desc: 'Bought/not bought item'
          end
        end

        def_param_group :shopping_list_item_params_group do 
          param :shopping_list_items, Array, of: Hash, desc: 'Scope of shopping list items' do
            param :servings, :number, desc: 'Number of servings'
            param :recipe_id, :number, desc: 'Recipe ID'
            param :recipe_ingredient_id, :number, desc: 'Recipe ingredient ID'
            param :text, String, desc: 'Name of shopping item'
            param :checked, :boolean, desc: 'Bought/not bought item'
          end
        end

        def_param_group :masterclass_params do
          param :masterclass_params, Hash, required: true, desc: 'Class params' do
            param :title, String, required: true, desc: 'Title of class'
            param :short_description, String, required: true, desc: 'Short description of class'
            param :long_description, String, required: true, desc: 'Long description of class'
            param :trailer_video_uid, String, required: false, desc: 'ID of Trailer Video'
            param :recipe_ids, Array, of: :number, required: false, desc: 'Recipe ids assigned to class'
            param :blog_post_ids, Array, of: :number, required: false, desc: 'Article ids assigned to class'
          end
          param :picture_ids, Array, of: :number, required: true, desc: 'Picture ids assigned to class'
          param :quiz_ids, Array, of: :number, required: false, desc: 'Quiz ids assigned to class'
          param :reward_ids, Array, of: :number, required: false, desc: 'Reward ids assigned to class'
          param :tutorial_ids, Array, of: :number, required: true, desc: 'Tutorial ids assigned to class'
          param :author_ids, Array, of: :number, required: true, desc: 'Authors of class'
        end

        def_param_group :user_params do
          property :user, Hash, desc: 'User params' do
            property :first_name, String, desc: 'User first name'
            property :last_name, String, desc: 'User last name'
            property :username, String, desc: 'User username'
            property :email, String, desc: 'User email'
            property :password, String, desc: 'User password'
            property :password_confirmation, String, desc: 'Confirmation password'
            property :location, String, desc: 'User location'
            property :description, String, desc: 'User`s description'
            property :site, String, desc: 'User site'
          end
        end

        def_param_group :create_update_params_planner_day do
          param :id, :number, desc: 'ID of planner_day'
          param :date, String, desc: 'Date of day'
          param :day_number, :number, required: false, desc: 'Number of day'
          param :breakfast_attributes, Array, of: Hash, desc: 'Attributes' do
            param :id, :number, desc: 'ID of breakfast meal'
            param :time, String, required: false, desc: 'Time of breakfast'
            param :recipe_id, :number, desc: 'ID of recipe'
          end
          param :lunches_attributes, Array, of: Hash, desc: 'Attributes' do
            param :id, :number, desc: 'ID of breakfast meal'
            param :time, String, required: false, desc: 'Time of breakfast'
            param :recipe_id, :number, desc: 'ID of recipe'
          end
          param :dinners_attributes, Array, of: Hash, desc: 'Attributes' do
            param :id, :number, desc: 'ID of breakfast meal'
            param :time, String, required: false, desc: 'Time of breakfast'
            param :recipe_id, :number, desc: 'ID of recipe'
          end
          param :snacks_attributes, Array, of: Hash, desc: 'Attributes' do
            param :id, :number, desc: 'ID of breakfast meal'
            param :time, String, required: false, desc: 'Time of breakfast'
            param :recipe_id, :number, desc: 'ID of recipe'
          end
          param :snacks2_attributes, Array, of: Hash, desc: 'Attributes' do
            param :id, :number, desc: 'ID of breakfast meal'
            param :time, String, required: false, desc: 'Time of breakfast'
            param :recipe_id, :number, desc: 'ID of recipe'
          end
        end

        def_param_group :recipe_detailed_params do
          property :recipe, Hash, desc: 'Recipe params' do
            property :id, Integer, desc: 'Recipe ID'
            property :title, String, desc: 'Name of recipe'
            property :description, String, desc: 'Description of recipe'
            property :video_link, String, desc: 'Link to video'
            property :preparation_time, Integer, desc: 'Time fo preparation recipe'
            property :cooking_time, Integer, desc: 'Time for cooking recipe'
            property :difficulty, String, desc: 'Difficulty of recipe'
            property :servings, Integer, desc: 'Servings of recipe'
            property :keywords, Array, of: String, desc: 'Keywords(tags) of recipe'
            property :state, String, desc: 'State of recipe'
            property :ingredients_count, Integer, desc: 'Count of ingredients'
            property :featured, :boolean, desc: 'Featured recipe or not'
            property :slug, String, desc: 'Slug of recipe'
            property :published_at, Datetime, desc: 'Time of publishing'
            property :views_count, Integer, desc: 'Count of view of recipe'
            property :weekly_newsletter, :boolean, desc: 'Weekly newsletter or not'
            property :nutrition_status, Integer, desc: 'Status of nutrition'
            property :premium, :boolean, desc: 'Premium recipe'
            param_group :group_of_ingredients
          end

        end

        def_param_group :group_of_ingredients do
          property :ingredients_groups, Array, of: Hash, desc: 'List of ingredients for recipe' do
            property :id, Integer, desc: 'Ingredients group id'
            property :name, String, desc: 'Ingredients group name'
            property :position, Integer, desc: 'Ingredients group position'
          end
        end
      end
    end
  end
end
