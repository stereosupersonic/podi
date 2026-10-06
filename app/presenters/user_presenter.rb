class UserPresenter < ApplicationPresenter
  def name
    [ o.first_name, o.last_name ].compact_blank.join(" ")
  end

  def admin
    h.show_boolean_value(o.admin?)
  end
end
