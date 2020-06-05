# frozen_string_literal: true

module Videos
  module Monitoring
    class StartFrom < BaseService
      param :video
      param :user

      option :mongo_client, default: proc { MongoClient.client }
      option :collection, default: proc { mongo_client[:video_tracker] }

      def call
        return 0 unless find_user_data

        find_user_data['time'].to_i
      end

      private

      def find_user_data
        @find_user_data ||= collection.find({ user_id: user.id, video_id: video.id }).first
      end
    end
  end
end
