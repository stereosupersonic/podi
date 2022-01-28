module Admin
  class Admin::EventsController < BaseController
    def index
      @event_records = Event.order(downloaded_at: :desc).paginate(page: params[:page], per_page: params[:per_page])
      @events = EventPresenter.wrap @event_records
    end

    def show
      @event_record = Event.find params[:id]
      @event = EventPresenter.new @event_record
    end
  end
end
