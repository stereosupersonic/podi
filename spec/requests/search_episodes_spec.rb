require "rails_helper"

RSpec.describe "Episode Search", type: :request do
  let!(:setting) { create(:setting) }

  describe "GET /episodes/search" do
    it "returns episodes matching title" do
      create(:episode, title: "Fahrrad Geschichte", number: 1)
      create(:episode, title: "Soli Wartenberg", number: 2)

      get "/episodes/search", params: { q: "Fahrrad" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Fahrrad Geschichte")
      expect(response.body).not_to include("Soli Wartenberg")
    end

    it "returns episodes matching description" do
      create(:episode, title: "Episode One", number: 1, description: "We talk about cycling routes")
      create(:episode, title: "Episode Two", number: 2, description: "We talk about cooking")

      get "/episodes/search", params: { q: "cycling" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Episode One")
      expect(response.body).not_to include("Episode Two")
    end

    it "returns episodes matching tags" do
      create(:episode, title: "Episode One", number: 1, tags: ["Technik", "Interview"])
      create(:episode, title: "Episode Two", number: 2, tags: ["Geschichte"])

      get "/episodes/search", params: { q: "Interview" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Episode One")
      expect(response.body).not_to include("Episode Two")
    end

    it "is case-insensitive" do
      create(:episode, title: "Fahrrad Geschichte", number: 1)

      get "/episodes/search", params: { q: "fahrrad" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Fahrrad Geschichte")
    end

    it "only returns published episodes" do
      create(:episode, title: "Draft Episode", number: 1, active: false)
      create(:episode, title: "Published Episode", number: 2)

      get "/episodes/search", params: { q: "Episode" }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Draft Episode")
      expect(response.body).to include("Published Episode")
    end

    it "returns ok when no matches" do
      get "/episodes/search", params: { q: "nonexistent" }

      expect(response).to have_http_status(:ok)
    end

    it "returns ok when query is blank" do
      get "/episodes/search", params: { q: "" }

      expect(response).to have_http_status(:ok)
    end

    it "renders inside a turbo frame" do
      get "/episodes/search", params: { q: "test" }

      expect(response.body).to include("turbo-frame")
      expect(response.body).to include("search_results")
    end
  end
end
