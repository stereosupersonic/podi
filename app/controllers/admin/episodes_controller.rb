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
      @episode = Episode.new number: Episode.maximum(:number).to_i.next
    end

    def create
      @episode = Episode.new episode_params
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
      @episode.assign_attributes(episode_params)
      @episode.slug = build_slug(@episode)

      if @episode.save
        redirect_to admin_episodes_path, notice: "Episode was successfully updated."
      else
        render :edit
      end
    end

    protected

    def build_slug(episode)
      return if episode.number.blank? || episode.title.blank?

      "#{episode.number.to_s.rjust(3, '0')} #{episode.title}".parameterize(locale: :de)
    end

    def episode_params
      params.require(:episode).permit(*Episode::ATTRIBUTES)
    end
  end
end
