require "rails_helper"

RSpec.describe "Sitemaps", type: :request do
  describe "GET /sitemap.xml" do
    it "returns success with XML content type" do
      get sitemap_path(format: :xml)

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("application/xml")
    end

    it "includes published episodes" do
      episode = create(:episode)

      get sitemap_path(format: :xml)

      expect(response.body).to include(episode_url(episode))
    end

    it "excludes unpublished episodes" do
      episode = create(:episode, active: false)

      get sitemap_path(format: :xml)

      expect(response.body).not_to include(episode_url(episode))
    end

    it "includes static pages" do
      get sitemap_path(format: :xml)

      expect(response.body).to include(root_url)
      expect(response.body).to include(episodes_url)
      expect(response.body).to include(about_url)
      expect(response.body).to include(imprint_url)
      expect(response.body).to include(privacy_url)
    end
  end
end
