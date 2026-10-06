require "rails_helper"

RSpec.describe "Rack::Attack pentester filter", type: :request do
  let!(:setting) { create(:setting) }

  around do |example|
    test_store = Rack::Attack.cache.store
    # Fail2Ban counts and bans in the cache, which is a null store in test.
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rack::Attack.reset!
    Rack::Attack.cache.store = test_store
  end

  def search(query)
    get "/episodes/search", params: { q: query }
  end

  context "with search terms that contain SQL keywords" do
    it "answers searches for Richard" do
      4.times { search("Richard") }

      expect(response).to have_http_status(:ok)
    end

    it "answers searches for union" do
      4.times { search("union") }

      expect(response).to have_http_status(:ok)
    end

    it "answers searches for Charts" do
      4.times { search("Charts") }

      expect(response).to have_http_status(:ok)
    end

    it "answers searches for order by date" do
      4.times { search("order by date") }

      expect(response).to have_http_status(:ok)
    end

    it "answers searches for words from a sentence" do
      4.times { search("Geschichten from Wartenberg and sleep") }

      expect(response).to have_http_status(:ok)
    end
  end

  context "with SQL injection in the query string" do
    it "blocks the request" do
      search("1 UNION SELECT password FROM users")

      expect(response).to have_http_status(:forbidden)
    end

    it "blocks a quoted tautology" do
      search("x' OR '1'='1")

      expect(response).to have_http_status(:forbidden)
    end

    it "bans the IP after three attempts" do
      3.times { search("1 UNION SELECT password FROM users") }
      search("Fahrrad")

      expect(response).to have_http_status(:forbidden)
    end

    it "does not ban the IP after two attempts" do
      2.times { search("1 UNION SELECT password FROM users") }
      search("Fahrrad")

      expect(response).to have_http_status(:ok)
    end
  end

  context "with a request for a known attack path" do
    it "blocks the request" do
      get "/wp-login.php"

      expect(response).to have_http_status(:forbidden)
    end

    it "bans the IP after three attempts" do
      3.times { get "/wp-login.php" }
      search("Fahrrad")

      expect(response).to have_http_status(:forbidden)
    end
  end
end
