module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods

      before_action :authenticate_api_token!

      rescue_from ActionController::ParameterMissing do |error|
        render_error :bad_request, error: "bad_request", message: "Missing parameter: #{error.param}"
      end

      private

      attr_reader :current_api_token

      def authenticate_api_token!
        @current_api_token = authenticate_with_http_token { |token, _options| ApiToken.authenticate(token) }
        return current_api_token.record_usage if current_api_token

        render_error :unauthorized, error: "unauthorized", message: "Missing or invalid API token"
      end

      def render_error(status, error:, message: nil, messages: nil)
        render json: { error: error, message: message, messages: messages }.compact, status: status
      end
    end
  end
end
