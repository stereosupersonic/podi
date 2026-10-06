require "rails_helper"

RSpec.describe "API v1 episodes", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:headers) { { "Authorization" => "Bearer #{ApiToken.issue(user: admin, name: 'agent').plaintext_token}" } }
  let(:jpg_path) { Rails.root.join("spec/fixtures/001-vorstellung.jpg") }
  let(:episode_params) do
    {
      title: "Neue Folge",
      description: "Wir reden über den Markt",
      nodes: "* Shownotes",
      published_on: Date.current.iso8601,
      audio: fixture_file_upload(Rails.root.join("spec/fixtures/test-001.mp3"), "audio/mpeg")
    }
  end

  before { create(:setting) }

  describe "POST /api/v1/episodes" do
    context "with valid attributes" do
      it "creates an inactive draft with a preview link", :aggregate_failures do
        create(:episode, number: 41)

        post "/api/v1/episodes", params: { episode: episode_params }, headers: headers

        episode = Episode.find_by!(title: "Neue Folge")
        expect(response).to have_http_status(:created)
        expect(response.headers["Location"]).to eq("http://wartenberger.test.com/episodes/042-neue-folge")
        expect(episode).to have_attributes(number: 42, slug: "042-neue-folge", active: false, visible: true)
        expect(response.parsed_body["episode"]).to include(
          "id" => episode.id,
          "number" => 42,
          "slug" => "042-neue-folge",
          "title" => "Neue Folge",
          "published_on" => Date.current.iso8601,
          "active" => false,
          "visible" => true,
          "tags" => [],
          "preview_url" => "http://wartenberger.test.com/episodes/042-neue-folge"
        )
      end

      it "keeps the draft off the public pages", :aggregate_failures do
        post "/api/v1/episodes", params: { episode: episode_params }, headers: headers

        get "/episodes"
        expect(response.body).not_to include("Neue Folge")

        get "/episodes.rss"
        expect(response.body).not_to include("Neue Folge")
      end

      it "makes the draft reachable by its preview link", :aggregate_failures do
        post "/api/v1/episodes", params: { episode: episode_params }, headers: headers

        get "/episodes/001-neue-folge"

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Neue Folge")
      end
    end

    context "with attributes the API does not accept" do
      it "ignores them", :aggregate_failures do
        post "/api/v1/episodes",
             params: { episode: episode_params.merge(active: true, visible: false, number: 99, rss_feed: false) },
             headers: headers

        expect(response).to have_http_status(:created)
        expect(Episode.last).to have_attributes(active: false, visible: true, number: 1, rss_feed: true)
      end
    end

    context "with the optional fields" do
      it "stores them", :aggregate_failures do
        post "/api/v1/episodes",
             params: { episode: episode_params.merge(
               chapter_marks: "00:00:01.000 Intro",
               transcript: "WEBVTT\n\n00:00:00.000 --> 00:00:02.000\nServus",
               tag_list: "Interview, Geschichte",
               image: fixture_file_upload(jpg_path, "image/jpeg")
             ) },
             headers: headers

        expect(response).to have_http_status(:created)
        episode = Episode.last
        expect(episode.chapter_marks).to eq("00:00:01.000 Intro")
        expect(episode.transcript).to start_with("WEBVTT")
        expect(episode.tags).to eq(%w[Interview Geschichte])
        expect(episode.image).to be_present
      end
    end

    context "with invalid attributes" do
      it "explains the validation errors per field", :aggregate_failures do
        post "/api/v1/episodes", params: { episode: { title: "" } }, headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        body = response.parsed_body
        expect(body["error"]).to eq("validation_failed")
        expect(body["messages"]).to include(
          "title" => [ "can't be blank" ],
          "audio" => [ "can't be blank" ],
          "published_on" => [ "can't be blank" ]
        )
        expect(body["message"]).to include("Title can't be blank")
      end
    end

    context "with audio that is not an mp3" do
      it "rejects the episode", :aggregate_failures do
        post "/api/v1/episodes",
             params: { episode: episode_params.merge(audio: fixture_file_upload(jpg_path, "audio/mpeg")) },
             headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body["messages"]["audio"]).to eq([ "must be an MP3 file (audio/mpeg)" ])
      end
    end

    context "with episode sent as a plain value" do
      it "answers bad request", :aggregate_failures do
        post "/api/v1/episodes", params: { episode: "Neue Folge" }, headers: headers

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to eq("error" => "bad_request", "message" => "Missing parameter: episode")
      end
    end

    context "with audio sent as text instead of a file" do
      it "explains that a file upload is needed", :aggregate_failures do
        post "/api/v1/episodes", params: { episode: episode_params.merge(audio: "folge.mp3") }, headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body["messages"]).to eq("audio" => [ "must be a file upload" ])
      end
    end

    context "with an image sent as text instead of a file" do
      it "explains that a file upload is needed", :aggregate_failures do
        post "/api/v1/episodes", params: { episode: episode_params.merge(image: "cover.jpg") }, headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body["messages"]).to eq("image" => [ "must be a file upload" ])
      end
    end

    context "without the episode key" do
      it "answers bad request", :aggregate_failures do
        post "/api/v1/episodes", params: { title: "Neue Folge" }, headers: headers

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to eq("error" => "bad_request", "message" => "Missing parameter: episode")
      end
    end

    context "without a valid token" do
      it "creates nothing", :aggregate_failures do
        expect do
          post "/api/v1/episodes", params: { episode: episode_params }
        end.not_to change(Episode, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
