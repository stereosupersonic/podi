module Admin
  class Admin::EventsController < BaseController
    def index
      @event_records = params[:episode_id].present? ? Event.where(episode_id: params[:episode_id]).order(downloaded_at: :desc) : Event.order(downloaded_at: :desc)
      @event_records = @event_records.paginate(page: params[:page], per_page: params[:per_page])
      @events = EventPresenter.wrap @event_records
    end

    def show
      @event_record = Event.find params[:id]
      @event = EventPresenter.new @event_record
    end
  end
end
