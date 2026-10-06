require "rails_helper"

RSpec.describe "API v1 rate limiting", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:headers) { { "Authorization" => "Bearer #{ApiToken.issue(user: admin, name: 'agent').plaintext_token}" } }
  let(:wrong_headers) { { "Authorization" => "Bearer podi_wrong" } }

  # The test environment uses :null_store, which never counts.
  before { allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new) }

  context "when a token sends 60 requests in a minute" do
    before { 60.times { get "/api/v1/ping", headers: headers } }

    it "answers all of them" do
      expect(response).to have_http_status(:ok)
    end

    it "answers the next request with rate_limited", :aggregate_failures do
      get "/api/v1/ping", headers: headers

      expect(response).to have_http_status(:too_many_requests)
      expect(response.parsed_body).to eq("error" => "rate_limited", "message" => "Too many requests, retry in a minute")
    end

    it "allows requests again after a minute" do
      get "/api/v1/ping", headers: headers

      travel 61.seconds do
        get "/api/v1/ping", headers: headers
        expect(response).to have_http_status(:ok)
      end
    end
  end

  context "when an IP fails authentication 10 times in a minute" do
    before { 10.times { get "/api/v1/ping", headers: wrong_headers } }

    it "answers the failed attempts with unauthorized" do
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects a valid token from that IP" do
      get "/api/v1/ping", headers: headers

      expect(response).to have_http_status(:too_many_requests)
    end

    it "accepts a valid token from another IP" do
      get "/api/v1/ping", headers: headers, env: { "REMOTE_ADDR" => "203.0.113.9" }

      expect(response).to have_http_status(:ok)
    end

    it "allows requests again after a minute" do
      travel 61.seconds do
        get "/api/v1/ping", headers: headers
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
