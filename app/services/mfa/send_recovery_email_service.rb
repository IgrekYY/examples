# frozen_string_literal: true

module Mfa
  class SendRecoveryEmailService < ApplicationService
    include Concerns::UserFinder
    # @attr_reader params [Hash]
    # - token: [String] Login token for User

    def call
      return { success: true } if user.role == 'root'

      update_user_recovery_status
      send_manager_emails if user.is_a?(Manager)
      send_admin_emails if user.is_a?(Admin)
    end

    private

    def user
      @user ||= find_user_by_token
    end

    def update_user_recovery_status
      user.update!(mfa_recovery_requested_at: Time.now, in_mfa_recovery_process: true)
    end

    def send_manager_emails
      if user.role == 'owner'
        user.mailer.reset_mfa_request_to_self_hq.deliver_now
        user.mailer.reset_mfa_request_to_metroengine.deliver_now
      else
        user.mailer.reset_mfa_request_to_self_other.deliver_now
        user.mailer.reset_mfa_request_to_owner.deliver_now
      end
    end

    def send_admin_emails
      user.mailer.reset_mfa_request_to_self.deliver_now
      user.mailer.reset_mfa_request_to_root.deliver_now
    end
  end
end
