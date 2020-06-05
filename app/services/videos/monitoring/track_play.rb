# frozen_string_literal: true

module Videos
  module Monitoring
    class TrackPlay < BaseService
      option :video_id, type: ->(value) { value.to_i }
      option :time, type: ->(value) { value.to_i }
      option :user

      option :mongo_client, default: proc { MongoClient.client }
      option :collection, default: proc { mongo_client[:video_tracker] }

      def call
        collection.update_one(
          { user_id: user.id, video_id: video_id },
          { '$set': { time: time } },
          upsert: true
        )
      end
    end
  end
end
