require "rails_helper"

RSpec.describe "Robots", type: :request do
  describe "GET /robots.txt" do
    it "returns success with text content type" do
      get "/robots.txt"

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("text/plain")
    end

    it "includes the sitemap URL" do
      get "/robots.txt"

      expect(response.body).to include(sitemap_url(format: :xml))
    end

    it "allows all crawlers" do
      get "/robots.txt"

      expect(response.body).to include("User-agent: *")
      expect(response.body).to include("Allow: /")
    end
  end
end
