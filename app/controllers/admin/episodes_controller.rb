module Admin
  class EpisodesController < BaseController
    skip_before_action :authorize_admin, only: [ :show ]

    def index
      @episode_records = Episode.order("number desc")
      @episodes = EpisodePresenter.wrap @episode_records
    end

    def show
      episode_record = Episode.find_by!(slug: params[:id])

      # HACK: for wrong url on facebook
      redirect_to episode_path slug: episode_record.slug
    end

    def new
      @episode = Episode.new number: Episode.next_number
    end

    def create
      @episode = EpisodeCreator.call(episode_attributes: create_params)
      if @episode.persisted?
        redirect_to admin_episodes_path, notice: "Episode was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
      @episode = Episode.find_by!(slug: params[:id])
    end

    def update
      @episode = Episode.find_by!(slug: params[:id])

      if @episode.update(update_params) && @episode.update(slug: @episode.build_slug)
        redirect_to admin_episodes_path, notice: "Episode was successfully updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    protected

    def create_params
      params.require(:episode).permit(*Episode::ATTRIBUTES)
    end

    def update_params
      params.require(:episode).permit(*Episode::ATTRIBUTES)
    end
  end
end
