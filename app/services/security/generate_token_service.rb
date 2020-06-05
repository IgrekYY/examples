# frozen_string_literal: true

module Security
  class GenerateTokenService < ApplicationService
    # @attr_reader params [Hash]:
    # - user: [User] (Admin or Manager)
    # - scope: [String]
    # - expires_in: [Integer]

    def call
      {
        access_token: access_token.token,
        token_type: 'bearer',
        expires_in: access_token.expires_in,
        refresh_token: access_token.refresh_token,
        created_at: access_token.created_at.to_time.to_i,
        scope: access_token.scopes
      }
    end

    private

    def access_token
      @access_token ||= Doorkeeper::AccessToken.create(
        resource_owner_id: param_user.id,
        refresh_token: generate_refresh_token,
        expires_in: param_expires_in,
        scopes: param_scope
      )
    end

    def param_user
      params[:user]
    end

    def param_expires_in
      params[:expires_in] || Doorkeeper.configuration.access_token_expires_in.to_i
    end

    def param_scope
      params[:scope]
    end

    def generate_refresh_token
      Digest::SHA1.hexdigest([Time.now, params.inspect, rand].join)
    end
  end
end
