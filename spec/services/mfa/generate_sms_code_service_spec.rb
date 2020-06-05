# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mfa::GenerateSmsCodeService do
  let(:admin) { create(:admin) }
  let(:params) { { user: admin } }

  subject { described_class.perform(params) }

  context 'when params are valid' do
    it 'updates admin attributes' do
      expect { subject }.to change(admin, :sms_secret_encrypted).and change(admin, :sms_secret_created_at)
    end
  end
end
