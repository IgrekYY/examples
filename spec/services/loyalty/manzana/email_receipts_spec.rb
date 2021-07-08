require 'rails_helper'

RSpec.describe Loyalty::Manzana::EmailReceipts do
  include Dry::Monads[:result]

  describe '#call' do
    context 'when user dont have email' do
      it 'returns Failure message' do
        user = build(:user, manzana_id: '33e932d7-76b3-43bc-8c71-49477455689e',
                            manzana_session_id: '67974def-1e74-4566-b7cc-e619aec8e1e7',
                            email: '')

        result = described_class.call(user: user)

        expect(result.failure).to eq('У пользователя отсуствует адрес электронной почты')
      end
    end

    context 'when user not registered in manzana Loyalty' do
      it 'returns Failure message' do
        user = build(:user, email: '')

        result = described_class.call(user: user)

        expect(result.failure).to eq('Пользователь не зарегистрирован в программе лояльности')
      end
    end

    context 'when user has email receipts flag' do
      context "with 'false' value" do
        it "returns Success with 'true' param" do
          user = create(:user, manzana_id: '33e932d7-76b3-43bc-8c71-49477455689e',
                               manzana_session_id: '67974def-1e74-4566-b7cc-e619aec8e1e7',
                               email: 'helen.goldner@friesen.us')
          allow(Manzana::UserProfileUpdate).to receive(:call).with(user: user).and_return(Success(true))

          result = described_class.call(user: user)

          expect(result.value!).to eq(enabled: true)
          expect(user.reload).to have_attributes(email_receipts_enabled: true)
        end
      end

      context "with 'true' value" do
        it "returns Success with 'false' param" do
          user = create(:user, manzana_id: '33e932d7-76b3-43bc-8c71-49477455689e',
                               manzana_session_id: '67974def-1e74-4566-b7cc-e619aec8e1e7',
                               email: 'helen.goldner@friesen.us',
                               email_receipts_enabled: true)
          allow(Manzana::UserProfileUpdate).to receive(:call).with(user: user).and_return(Success(true))

          result = described_class.call(user: user)

          expect(result.value!).to eq(enabled: false)
          expect(user.reload).to have_attributes(email_receipts_enabled: false)
        end
      end
    end
  end
end
