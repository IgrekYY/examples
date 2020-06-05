# frozen_string_literal: true

class ApplicationPresenter

  def initialize(record, view = ActionView::Base.new)
    @record = record
    @view = view
  end

  private

  def picture_presenter(present_method: :picture_page_context)
    return unless picture

    picture.present(nil).public_send(present_method)
  end

  def user_presenter(present_method: :user_page_context)
    return unless user

    user.present(nil).public_send(present_method)
  end

  def comment_presenter
    return unless comment_threads

    comment_threads.map { |comment| comment.present(nil).comment_threads_context }
  end

  attr_reader :record, :view
end
