# frozen_string_literal: true

module Api
  module V1
    class MasterclassesController < Api::ApplicationController
      include Api::Concerns::CommonParams

      api :GET, '/classes', 'List of Classes'
      param :featured, :boolean, desc: 'Only featured'
      param :order_by, %w[asc desc], desc: 'Order'
      param :title, String, desc: 'Name of Class'
      param_group :pagination
      # returns array_of:
      error code: 401, desc: 'Invalid or expired auth token'
      error code: 400, desc: 'Bad request'
      def index
        render_response(
          Masterclasses::FindListService.call(params.to_unsafe_h) do |one_masterclass|
            one_masterclass.present(view_context).masterclass_page_context(current_user)
          end
        )
      end

      api :GET, '/classes/details', 'Detaled information about Class'
      param :masterclass_id, :number, required: true, desc: 'ID of Class'
      # returns array_of:
      error code: 404, desc: 'Record not found'
      error code: 401, desc: 'Invalid or expired auth token'
      error code: 400, desc: 'Bad request'
      def show
        raise Errors::RecordNotFound if masterclass.blank?
        raise Errors::AccessDenied unless current_user.pro? || current_user.admin?

        ViewsCountService.update_count(masterclass, 1)
        render_response(masterclass.present(view_context).masterclass_detailed_page_context(current_user))
      end

      api :POST, '/classes', 'Create class'
      param_group :masterclass_params
      # returns array_of:
      error code: 404, desc: 'Record not found'
      error code: 401, desc: 'Invalid or expired auth token'
      error code: 400, desc: 'Bad request'
      def create
        render_monad_response(
          Masterclasses::Create.call(params.to_unsafe_h.merge(user: current_user))
        )
      end

      api :PUT, '/classes/details', 'Update class'
      param :masterclass_id, :number, required: true, desc: 'ID of Class'
      param_group :masterclass_params
      # returns array_of:
      error code: 404, desc: 'Record not found'
      error code: 401, desc: 'Invalid or expired auth token'
      error code: 400, desc: 'Bad request'
      def update
        render_monad_response(
          Masterclasses::Update.call(params.to_unsafe_h.merge(user: current_user, masterclass: masterclass))
        )
      end

      api :POST, '/classes/enroll_user', 'Enroll user'
      param :masterclass_id, :number, required: true, desc: 'ID of Class'
      # returns array_of:
      error code: 404, desc: 'Record not found'
      error code: 401, desc: 'Invalid or expired auth token'
      error code: 400, desc: 'Bad request'
      def enroll_user
        raise Errors::AccessDenied unless current_user.pro?

        masterclass.users << current_user
        render json: true
      end

      api :DELETE, '/classes', 'Destroy masterclass'
      param :masterclass_id, :number, required: true, desc: 'ID of Class'
      # returns array_of:
      error code: 404, desc: 'Record not found'
      error code: 401, desc: 'Invalid or expired auth token'
      error code: 400, desc: 'Bad request'
      def destroy
        masterclass.destroy
        render json: true
      end

      api :DELETE, '/classes/destroy_link_rewards', 'Delete reward from class'
      param :masterclass_id, :number, required: true, desc: 'ID of Class'
      param :reward_id, :number, required: true, desc: 'ID of Reward'
      # returns array_of:
      error code: 404, desc: 'Record not found'
      error code: 401, desc: 'Invalid or expired auth token'
      error code: 400, desc: 'Bad request'
      def destroy_link_rewards
        masterclass.rewards.delete(Reward.find(params[:reward_id]))
        render json: true
      end

      api :DELETE, '/classes/destroy_link_tutorials', 'Delete reward from class'
      param :masterclass_id, :number, required: true, desc: 'ID of Class'
      param :tutorial_id, :number, required: true, desc: 'ID of tutorial'
      # returns array_of:
      error code: 404, desc: 'Record not found'
      error code: 401, desc: 'Invalid or expired auth token'
      error code: 400, desc: 'Bad request'
      def destroy_link_tutorials
        masterclass.tutorials.delete(Tutorial.find(params[:tutorial_id]))
        render json: true
      end

      api :DELETE, '/classes/destroy_link_authors', 'Delete author from class'
      param :masterclass_id, :number, required: true, desc: 'ID of Class'
      param :author_id, :number, required: true, desc: 'ID of author'
      # returns array_of:
      error code: 404, desc: 'Record not found'
      error code: 401, desc: 'Invalid or expired auth token'
      error code: 400, desc: 'Bad request'
      def destroy_link_authors
        masterclass.authors.delete(User.find(params[:author_id]))
        render json: true
      end

      private

      def masterclass
        @masterclass ||= Masterclass.find(params[:masterclass_id])
      end
    end
  end
end
