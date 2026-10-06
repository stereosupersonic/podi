module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods

      REQUESTS_PER_TOKEN_PER_MINUTE = 60
      FAILED_AUTHENTICATIONS_PER_IP_PER_MINUTE = 10

      before_action :authenticate_api_token!
      before_action :limit_requests_per_token

      rescue_from ActionController::ParameterMissing do |error|
        render_error :bad_request, error: "bad_request", message: "Missing parameter: #{error.param}"
      end

      private

      attr_reader :current_api_token

      def authenticate_api_token!
        return render_rate_limited if failed_authentications_exceeded?

        @current_api_token = authenticate_with_http_token { |token, _options| ApiToken.authenticate(token) }
        return current_api_token.record_usage if current_api_token

        Rails.cache.increment(failed_authentications_key, 1, expires_in: 1.minute)
        render_error :unauthorized, error: "unauthorized", message: "Missing or invalid API token"
      end

      def limit_requests_per_token
        count = Rails.cache.increment("api:requests:#{current_api_token.id}", 1, expires_in: 1.minute)
        render_rate_limited if count.to_i > REQUESTS_PER_TOKEN_PER_MINUTE
      end

      # raw: true because increment stores a raw integer, which Redis cannot read back deserialized.
      def failed_authentications_exceeded?
        Rails.cache.read(failed_authentications_key, raw: true).to_i >= FAILED_AUTHENTICATIONS_PER_IP_PER_MINUTE
      end

      def failed_authentications_key
        "api:failed-authentications:#{request.remote_ip}"
      end

      def render_rate_limited
        render_error :too_many_requests, error: "rate_limited", message: "Too many requests, retry in a minute"
      end

      def render_error(status, error:, message: nil, messages: nil)
        render json: { error: error, message: message, messages: messages }.compact, status: status
      end
    end
  end
end
