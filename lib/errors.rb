# frozen_string_literal: true

# In this file you can define a custom error class for exception that should be caught by
#   the controller and sent in API response.
# Firstly you should choose a group of HTTP status that should be sent with your error.
# Add new error class below in related group. The name of class should be unique. Name of
#   your class will be converted to custom error code that will be sent in response. For
#   example: for class `UnacceptablePassword` error code will be ‘unacceptable_password’.
# Add your error class to list of exceptions in related presenter class in
#   lib/errors/presenters.
# After that the controller will handle your exception and build nice response with custom
#   error code.

require_relative './errors/abstract_presenter'
require_relative './errors/controller_handlers'
require_relative './errors/registry'

module Errors

  # ========== Custom errors of group 400 Bad Request
  # ==================================================

  class UnknownUser < StandardError
    def message
      'Unknown user'
    end
  end

  class EmailСonfirmation < StandardError
    def message
      'Need to confirm your email'
    end
  end

  class UnknownResetPasswordToken < StandardError
    def message
      'Unknown reset password token'
    end
  end

  class UserAlreadyInMasterclass < StandardError
    def message
      'User have alredy subscribed on that masterclass'
    end
  end
  # ========== Custom errors of group 401 Unauthorized
  # ==================================================

  class NotAuthorized < StandardError
    def message
      'Missing access token'
    end
  end

  class EmptyAuthInfoOrEmail < StandardError
    def message
      'Empty authentication params from provider'
    end
  end

  # ========== Custom errors of group 403 Forbidden
  # ==================================================

  class AccessDenied < StandardError
    def message
      'You don`t have permissions to see the masterclass'
    end
  end

  # ========== Custom errors of group 404 Not Found
  # ==================================================

  class UnknownUserEmail < StandardError
    def message
      'Email address is not registered'
    end
  end

  class RecordNotFound < StandardError
    def message
      'Record not found'
    end
  end

  class UserNotFound < StandardError
    def message
      'User not found'
    end
  # ========== Custom errors of group 422 Unprocessable Entity
  # ==================================================

  end
end
