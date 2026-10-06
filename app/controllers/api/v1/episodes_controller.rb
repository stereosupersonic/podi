module Api
  module V1
    class EpisodesController < BaseController
      PERMITTED_ATTRIBUTES = %i[
        title description nodes published_on audio image chapter_marks transcript tag_list
      ].freeze
      FILE_ATTRIBUTES = %w[audio image].freeze

      # Episodes created through the API are drafts: unlisted but reachable by link
      # until a human ticks "Active" in the admin.
      DRAFT_ATTRIBUTES = { active: false, visible: true }.freeze

      def create
        return render_file_errors if text_instead_of_files.any?

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
        episode = params.require(:episode)
        raise ActionController::ParameterMissing, :episode unless episode.is_a?(ActionController::Parameters)

        episode.slice(*PERMITTED_ATTRIBUTES).permit(*PERMITTED_ATTRIBUTES)
      end

      # Active Storage and Shrine treat a string as a reference to an existing upload and raise.
      def text_instead_of_files
        FILE_ATTRIBUTES.select do |name|
          episode_params.key?(name) && !episode_params[name].is_a?(ActionDispatch::Http::UploadedFile)
        end
      end

      def render_file_errors
        render_error :unprocessable_content,
                     error: "validation_failed",
                     message: "#{text_instead_of_files.to_sentence} must be a file upload",
                     messages: text_instead_of_files.index_with { [ "must be a file upload" ] }
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
