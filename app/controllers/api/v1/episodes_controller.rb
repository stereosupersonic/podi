module Api
  module V1
    class EpisodesController < BaseController
      PERMITTED_ATTRIBUTES = %i[
        title description nodes published_on audio image chapter_marks transcript tag_list
      ].freeze

      # Episodes created through the API are drafts: unlisted but reachable by link
      # until a human ticks "Active" in the admin.
      DRAFT_ATTRIBUTES = { active: false, visible: true }.freeze

      def create
        @episode = EpisodeCreator.call(episode_attributes: episode_params.merge(DRAFT_ATTRIBUTES))
        if @episode.persisted?
          render :show, status: :created, location: EpisodePresenter.new(@episode).episode_url
        else
          render_validation_errors
        end
      end

      private

      # Unknown keys are sliced away before permit so they are ignored the same way in every
      # environment (test raises on unpermitted parameters, production only logs them).
      def episode_params
        params.require(:episode).slice(*PERMITTED_ATTRIBUTES).permit(*PERMITTED_ATTRIBUTES)
      end

      def render_validation_errors
        render_error :unprocessable_content,
                     error: "validation_failed",
                     message: @episode.errors.full_messages.to_sentence,
                     messages: @episode.errors.to_hash
      end
    end
  end
end
