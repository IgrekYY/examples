# frozen_string_literal: true

class MongoClient < Mongo::Client
  def initialize(array = [ ENV['MONGO_DB_HOST'] ],
                 database: ENV['MONGO_DB_NAME'],
                 user: ENV['MONGO_DB_USER'],
                 password: ENV['MONGO_DB_PASSWORD'],
                 auth_source: 'admin')
  end
end
