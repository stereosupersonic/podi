class StatisticPresenter < ApplicationPresenter
  FIELDS = %i[a12h a1d a7d a3d a7d a14d a30d a60d a3m a6m a12m a18m a24m].freeze

  FIELDS.each do |field|
    define_method(field) do
      o.send(field).zero? ? "-" : o.send(field)
    end
  end
end
