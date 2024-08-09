require "delegate"

class ApplicationPresenter < SimpleDelegator
  alias object __getobj__

  delegate :current_setting, to: :helpers

  def self.wrap(collection)
    return [] unless collection

    collection.map { |elem| new(elem) }
  end

  def helpers
    ApplicationController.helpers
  end

  def created_at
    h.format_datetime o.created_at
  end

  def current_setting
    @current_setting ||= Setting.current
  end

  alias h helpers
  alias o object
end
