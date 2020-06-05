# frozen_string_literal: true

module Webhooks
  class StripeController < ApplicationController
    skip_before_action :authenticate
    protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == 'application/json' }

    def index
      sig_header = request.env['HTTP_STRIPE_SIGNATURE']

      begin
        event = Stripe::Webhook.construct_event(request.body.read, sig_header, Rails.configuration.stripe_webhook_secret)
      rescue JSON::ParserError
        return head :bad_request
      rescue Stripe::SignatureVerificationError
        return head :bad_request
      end

      case event['type']
      when 'checkout.session.completed'
        Subscriptions::Sessions::SuccessCheckout.call(event)
      when 'plan.created'
        Subscriptions::Plans::Create.call(event)
      when 'plan.updated'
        Subscriptions::Plans::Update.call(event)
      when 'plan.deleted'
        Subscriptions::Plans::Delete.call(event)
      when 'customer.subscription.deleted'
        Subscriptions::Users::Delete.call(event)
      end

      head :ok
    end
  end
end