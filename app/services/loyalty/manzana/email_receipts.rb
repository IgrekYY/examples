class Loyalty::Manzana::EmailReceipts
  include Dry::Monads[:result]

  def self.call(...)
    new(...).call
  end

  def initialize(user:)
    @user = user
  end

  def call
    return Failure('Пользователь не зарегистрирован в программе лояльности') unless user.manzana?
    return Failure('У пользователя отсуствует адрес электронной почты') if user.email.blank?

    toggle_flag!
    result = ::Manzana::UserProfileUpdate.call(user: user)

    case result
    when Success
      Success(enabled: user.email_receipts_enabled)
    when Failure
      toggle_flag!
      Failure(result.failure)
    end
  end

  private

  def toggle_flag!
    user.update!(email_receipts_enabled: !user.email_receipts_enabled)
  end

  attr_reader :user
end
