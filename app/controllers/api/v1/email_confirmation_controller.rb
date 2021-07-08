class Api::V1::Users::EmailConfirmationsController < ApiApplicationController
  before_action :authenticate_user!

  include Dry::Monads[:result]

  def set_email
    service_call(User::EmailActions::SetUnconfirmedEmail, { user: current_user, email: params.require(:email) })
  end

  def send_code
    service_call(User::EmailActions::SendConfirmation, { user: current_user })
  end

  def confirm
    service_call(User::EmailActions::Confirm, { user: current_user, code: params.require(:code) })
  end

  private

  def service_call(name, params)
    @user = params[:user]
    result = name.call(**params)

    case result
    when Success
      render 'index'
    when Failure
      respond_with_error result.failure
    end
  end
end
