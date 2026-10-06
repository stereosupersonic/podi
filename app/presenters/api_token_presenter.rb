class ApiTokenPresenter < ApplicationPresenter
  def last_used
    h.format_datetime(o.last_used_at).presence || "Never"
  end
end
