class RemoteFileStatus < BaseService
  attr_accessor(:url)

  def call
    status = remote_file_exits? url
    OpenStruct.new status: status, message: status_text
  end

  private

  attr_reader :status_text

  def remote_file_exits?(url, method: :get)
    Rails.logger.info "check url: #{url}"
    conn = Faraday.new do |b|
      b.use FaradayMiddleware::FollowRedirects
      b.adapter :net_http
      b.options.timeout = 3
    end
    request = conn.send method, url
    @status_text = "status: #{request.status}"
    Rails.logger.info @status_text
    request.success? ? :ok : :error
  rescue Faraday::Error, Faraday::Error::ConnectionFailed => e
    Rails.logger.fatal e
    @status_text = e.message
    :fatal
  end
end
