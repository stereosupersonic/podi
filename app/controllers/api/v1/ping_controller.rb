module Api
  module V1
    class PingController < BaseController
      def show
        @api_token = current_api_token
      end
    end
  end
end
