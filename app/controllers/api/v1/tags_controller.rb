module Api
  module V1
    class TagsController < BaseController
      def index
        @tags = Episode.all_tags
      end
    end
  end
end
