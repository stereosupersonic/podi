module Admin
  class EpisodesController < BaseController
    def index
      @episode_records = Episode.order("number desc")
      @episodes = EpisodePresenter.wrap @episode_records
    end

    def new
      @episode = Episode.new number: Episode.maximum(:number).to_i.next
    end

    def create
      @episode = Episode.new create_params
      @episode.slug = build_slug(@episode)
      if @episode.save
        redirect_to admin_episodes_path, notice: "Episode was successfully created."
      else
        render :new
      end
    end

    def edit
      @episode = Episode.find_by!(slug: params[:id])
    end

    def update
      @episode = Episode.find_by!(slug: params[:id])
      if @episode.update(update_params) && @episode.update(slug: build_slug(@episode))
        redirect_to admin_episodes_path, notice: "Episode was successfully updated."
      else
        render :edit
      end
    end

    protected

    def build_slug(episode)
      return if episode.number.blank? || episode.title.blank?
      "#{episode.number.to_s.rjust(3, "0")} #{episode.title}".parameterize(locale: :de)
    end

    def create_params
      params.require(:episode).permit(*Episode::ATTRIBUTES)
    end

    def update_params
      params.require(:episode).permit(*Episode::ATTRIBUTES)
    end
  end
end
