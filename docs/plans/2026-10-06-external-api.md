# External API with Token Access: Implementation Plan

## Overview

Admins create personal **API tokens** in the admin area. A token authenticates a JSON API that lets a
script or a shell-capable AI agent (Claude Code, Codex, n8n with file access) **create new episodes**.
Episodes created through the API are **never public until a human approves them**: they are created with
`active: false` (not listed on the homepage, the episode list, search, RSS or the sitemap) and
`visible: true` (reachable by direct link, so the creator can share a preview URL). An admin approves an
episode by ticking "Active" in the existing admin edit form.

v1 consists of:

| Piece | What it is |
|---|---|
| `EpisodeCreator` | Service shared by the admin form and the API: assigns the next number, builds the slug, saves |
| MP3 validation | `Episode#audio` must be `audio/mpeg` (admin and API) |
| Column default | `episodes.active` defaults to `false`; the admin index shows a "Draft" badge |
| `ApiToken` | Model storing only a SHA-256 digest of each token; plaintext is shown once |
| Admin UI | `/admin/api_tokens`: list, create (shows the token once), revoke |
| `GET /api/v1/ping` | Checks a token and says whose it is |
| `POST /api/v1/episodes` | Multipart create of a draft episode |
| `GET /api/v1/tags` | Every tag in use, so an agent can reuse existing tags instead of inventing variants |
| Rate limits | 60 requests/minute per token, 10 failed authentications/minute per IP |
| `docs/api.md` | API documentation written for an AI agent to read |

**Out of scope for v1** (decided, do not build): updating episodes via the API (`PATCH`), episode
ownership (`user_id` on episodes), token expiry, notifications, `audio_url` downloads, OpenAPI/MCP.
The contract must stay compatible with adding `audio_url` later (see Task 10).

**Branch:** `external_api` (already exists, branched from `master`). Work and commit there.

---

## Prerequisites: Read These First

| File | Why |
|---|---|
| `AGENTS.md` | Project conventions, spec layout, episode visibility rules |
| `app/models/episode.rb` | Model you will extend; note `ATTRIBUTES`, `published` scope, validations |
| `app/controllers/admin/episodes_controller.rb` | Contains `build_slug` and the number default you will extract |
| `app/controllers/admin/base_controller.rb` | `authorize_admin` guard for admin controllers |
| `app/controllers/application_controller.rb` | `current_user`, `authorize_admin` |
| `app/services/base_service.rb`, `app/services/fetch_geo_data.rb` | Service object pattern: `attr_accessor` + `call` |
| `app/views/admin/episodes/*.html.haml` | Admin page markup and SimpleForm usage to copy |
| `app/views/layouts/application.html.haml` (lines ~74-80) | Admin navigation links |
| `app/helpers/application_helper.rb` | `add_button`, `back_button`, `submit_button`, `format_datetime` |
| `config/initializers/strong_params.rb` | **Unpermitted params raise in test, only log in production.** Matters for Task 7 |
| `config/routes.rb` | Note the catch-all `get ":id"` at the end |
| `spec/system/admin/episodes_spec.rb` | Admin system spec style and the table matcher |
| `spec/requests/episodes_spec.rb` | Request spec style |
| `spec/factories/episodes.rb`, `spec/factories/users.rb` | Factories (the user factory has a fixed email; the `:admin` trait uses another) |
| `spec/support/login_helpers.rb` | `login_as(user)` for system specs |

## Conventions You Must Follow

- **TDD for every task:** write the failing spec, run it and watch it fail **for the expected reason**,
  write the minimal code, run it green, refactor.
- **Run only targeted specs locally** (the ones named in each task). The full suite runs in CI.
- **HAML**, never ERB. **Double quotes.** Match the surrounding code.
- Strong params: `params.require(:x).permit(...)`, like the existing controllers.
- Status code for validation failures: `:unprocessable_content` (Rack 3.2 is installed;
  `:unprocessable_entity` is deprecated).
- **Commits:** one per task (or smaller), conventional prefix, imperative, summary under 50 characters.
  **No `Co-Authored-By` or any tool or assistant attribution** in commits or the PR.
- Don't touch whitespace in code you aren't changing.

## Task 0: Get the Environment Running

Some gems in `Gemfile.lock` are not installed locally.

```sh
bundle install
bin/rails db:prepare
bin/rspec spec/models/episode_spec.rb spec/system/admin/episodes_spec.rb spec/requests/episodes_spec.rb
```

All three must be green **before** you change anything. If they aren't, stop and report it; don't start
on a red baseline.

---

## Task 1: Extract `EpisodeCreator`, `Episode.next_number` and `Episode#build_slug`

**Goal:** move the number default and the slug building out of `Admin::EpisodesController` so the API can
reuse them. **No behaviour change.** The existing admin system specs are your safety net.

### 1a. Failing model specs

Add to `spec/models/episode_spec.rb`:

```ruby
  describe ".next_number" do
    it "is 1 when there are no episodes" do
      expect(described_class.next_number).to eq(1)
    end

    it "is one more than the highest number" do
      create(:episode, number: 7)
      create(:episode, number: 3)

      expect(described_class.next_number).to eq(8)
    end
  end

  describe "#build_slug" do
    it "combines the zero-padded number and the title" do
      episode = described_class.new(number: 42, title: "Über den Markt")

      expect(episode.build_slug).to eq("042-ueber-den-markt")
    end

    it "is nil without a title" do
      expect(described_class.new(number: 42).build_slug).to be_nil
    end
  end
```

Run `bin/rspec spec/models/episode_spec.rb` and confirm they fail with `NoMethodError`.

### 1b. Implement in `app/models/episode.rb`

Below the scopes:

```ruby
  def self.next_number
    maximum(:number).to_i.next
  end
```

Below `audio_size`:

```ruby
  def build_slug
    return if number.blank? || title.blank?

    "#{number.to_s.rjust(3, '0')} #{title}".parameterize(locale: :de)
  end
```

This is the exact logic of `Admin::EpisodesController#build_slug`. Check the German transliteration
(`Ü` → `ue`) is green; it depends on the `de` locale's transliteration rules in `config/locales/de.yml`.
If `"042-uber-den-markt"` comes out instead, **do not change the expectation**. The existing admin
behaviour is the reference, so check what the admin produces today, write the spec to match it, and
mention it in the PR.

### 1c. Failing service spec

Create `spec/services/episode_creator_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe EpisodeCreator do
  let(:attributes) do
    {
      title: "Neue Folge",
      description: "description",
      nodes: "* notes",
      published_on: Date.current,
      audio: Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/test-001.mp3"), "audio/mpeg")
    }
  end

  it "saves the episode with the next number and a slug" do
    create(:episode, number: 4)

    episode = described_class.call(episode_attributes: attributes)

    expect(episode).to be_persisted
    expect(episode.number).to eq(5)
    expect(episode.slug).to eq("005-neue-folge")
  end

  it "keeps an explicitly given number" do
    episode = described_class.call(episode_attributes: attributes.merge(number: 12))

    expect(episode.number).to eq(12)
    expect(episode.slug).to eq("012-neue-folge")
  end

  it "returns the unsaved episode with errors when invalid" do
    episode = described_class.call(episode_attributes: attributes.merge(title: ""))

    expect(episode).not_to be_persisted
    expect(episode.errors[:title]).to include("can't be blank")
  end

  it "reports a number collision from the database as a validation error" do
    # Two creates racing for the same number pass validation, and the unique index rejects the second.
    episode = Episode.new
    allow(Episode).to receive(:new).and_return(episode)
    allow(episode).to receive(:save).and_raise(ActiveRecord::RecordNotUnique)

    result = described_class.call(episode_attributes: attributes)

    expect(result).not_to be_persisted
    expect(result.errors[:number]).to include("has already been taken")
  end
end
```

**Why `number.to_i.positive?` below and not `number.blank?`:** the `number` column has a DB default of
`0`, so `Episode.new` has `number == 0`, never `nil`. `0` means "not given".

### 1d. Implement `app/services/episode_creator.rb`

```ruby
class EpisodeCreator < BaseService
  attr_accessor :episode_attributes

  def call
    episode = Episode.new(episode_attributes)
    episode.number = Episode.next_number unless episode.number.to_i.positive?
    episode.slug = episode.build_slug
    save(episode)
  end

  private

  def save(episode)
    episode.save
    episode
  rescue ActiveRecord::RecordNotUnique
    episode.errors.add(:number, :taken)
    episode
  end
end
```

Run `bin/rspec spec/services/episode_creator_spec.rb`; it should be green.

### 1e. Use it in the admin controller

In `app/controllers/admin/episodes_controller.rb`:

```ruby
    def new
      @episode = Episode.new number: Episode.next_number
    end

    def create
      @episode = EpisodeCreator.call(episode_attributes: create_params)
      if @episode.persisted?
        redirect_to admin_episodes_path, notice: "Episode was successfully created."
      else
        render :new
      end
    end
```

In `update`, replace `build_slug(@episode)` with `@episode.build_slug`. Delete the controller's
`build_slug` method.

### 1f. Verify and commit

```sh
bin/rspec spec/models/episode_spec.rb spec/services/episode_creator_spec.rb spec/system/admin/episodes_spec.rb
bin/rubocop app/models/episode.rb app/services/episode_creator.rb app/controllers/admin/episodes_controller.rb spec/services/episode_creator_spec.rb spec/models/episode_spec.rb
git add app/models/episode.rb app/services/episode_creator.rb app/controllers/admin/episodes_controller.rb spec/models/episode_spec.rb spec/services/episode_creator_spec.rb
git commit -m "refactor: extract EpisodeCreator service"
```

---

## Task 2: Only Accept MP3 Audio

**Goal:** `Episode` rejects audio that isn't `audio/mpeg`. Active Storage determines `content_type` from
the file's bytes (Marcel), so a client can't fake it with a header.

### 2a. Failing specs in `spec/models/episode_spec.rb`

```ruby
  describe "audio validation" do
    it "accepts an mp3" do
      expect(build(:episode)).to be_valid
    end

    it "rejects a file that is not an mp3, even when declared as audio/mpeg" do
      image = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/001-vorstellung.jpg"), "audio/mpeg")
      episode = build(:episode, audio: image)

      expect(episode).not_to be_valid
      expect(episode.errors[:audio]).to include("must be an MP3 file (audio/mpeg)")
    end
  end
```

Run it. The second example must fail because the episode **is valid**. If it fails differently (e.g. the
content type isn't `image/jpeg`), investigate before continuing.

### 2b. Implement in `app/models/episode.rb`

Next to the other validations:

```ruby
  validate :audio_must_be_mp3
```

At the end of the class (the model has no `private` section yet; add one):

```ruby
  private

  def audio_must_be_mp3
    return unless audio.attached?
    return if audio.content_type == "audio/mpeg"

    errors.add(:audio, "must be an MP3 file (audio/mpeg)")
  end
```

### 2c. Verify and commit

```sh
bin/rspec spec/models/episode_spec.rb spec/system/admin/episodes_spec.rb
git commit -am "feat: only accept mp3 audio for episodes"
```

**Before this reaches production** someone must run the pre-flight check in Task 11. Old episodes with a
different stored content type would otherwise fail validation when edited.

---

## Task 3: Episodes Are Inactive by Default; "Draft" Badge in the Admin

### 3a. Failing model spec

```ruby
  it "is inactive by default" do
    expect(described_class.new.active).to be(false)
  end
```

### 3b. Migration

```sh
bin/rails g migration ChangeActiveDefaultOnEpisodes
```

```ruby
class ChangeActiveDefaultOnEpisodes < ActiveRecord::Migration[8.1]
  def change
    change_column_default :episodes, :active, from: true, to: false
  end
end
```

```sh
bin/rails db:migrate
```

`db/schema.rb` changes, and the `annotate` gem rewrites the schema comment blocks in the model, factory
and spec files (`default(FALSE)` for `active`). Commit those comment changes too.

### 3c. Keep the factory meaning "a released episode"

Most specs (homepage, list, RSS, sitemap) create episodes with the factory and expect them to be public.
They relied on the old default. In `spec/factories/episodes.rb` add:

```ruby
    active { true }
```

Then search for episodes created without the factory: `grep -rn "Episode.create\|Episode.new" spec db/seeds.rb`.
Make sure none of them relies on the old default.

### 3d. Draft badge

In `app/views/admin/episodes/index.html.haml`, replace the "Published" cell:

```haml
          %td
            = show_boolean_value episode.published?
            - unless episode.active?
              %span.badge.text-bg-warning Draft
```

Also fix the misleading `visible` hint in `app/views/admin/episodes/_form.html.haml`. `visible` only
controls whether the episode can be reached by direct link; listing and the RSS feed depend on `active`
and `rss_feed`. Replace:

```haml
= f.input :visible, as: :boolean, hint: "is the episode visible on the website and RSS feed"
```

with:

```haml
= f.input :visible, as: :boolean, hint: "Reachable by direct link, e.g. for previews. Listing on the website and in the RSS feed needs \"Active\""
```

This is copy only; no spec asserts the hint text (check with `grep -rn "visible on the website" spec`).

### 3e. Update the admin system spec

In `spec/system/admin/episodes_spec.rb`, the example **"create a new episode"** now creates an inactive
episode (the "Active" checkbox starts unticked). In its second `have_table_with_exact_data`, change the
first cell of the data row from `""` to `"Draft"`, and add after the table assertion:

```ruby
      expect(last_episode.active).to be(false)
```

Add an example proving that the badge disappears for released episodes. The existing "overview page"
example already covers this: its factory episode is active and its first cell stays `""`.

### 3f. Verify and commit

```sh
bin/rspec spec/models/episode_spec.rb spec/system/admin/episodes_spec.rb spec/requests spec/system/episodes_spec.rb spec/system/welcome_spec.rb
git add db/migrate db/schema.rb app/models/episode.rb app/views/admin/episodes/index.html.haml app/views/admin/episodes/_form.html.haml spec/factories/episodes.rb spec/models/episode_spec.rb spec/system/admin/episodes_spec.rb
git status   # check for annotate changes elsewhere and add them deliberately
git commit -m "feat: make new episodes inactive by default"
```

---

## Task 4: `ApiToken` Model

**Design:** the plaintext token (`podi_` + 43 base58 characters, about 256 bits) is shown once. Only
`SHA256(plaintext)` is stored, looked up through a unique index. A salted slow hash (bcrypt) is not
needed for random 256-bit secrets, and it would make lookup by digest impossible. A token only
authenticates while its user is an admin.

### 4a. Migration

```sh
bin/rails g migration CreateApiTokens
```

```ruby
class CreateApiTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :api_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :token_digest, null: false
      t.datetime :last_used_at
      t.timestamps
    end
    add_index :api_tokens, :token_digest, unique: true
  end
end
```

```sh
bin/rails db:migrate
```

### 4b. Failing specs: `spec/models/api_token_spec.rb`

```ruby
require "rails_helper"

RSpec.describe ApiToken do
  let(:admin) { create(:user, :admin) }

  describe ".issue" do
    it "creates a token and exposes the plaintext once" do
      token = described_class.issue(user: admin, name: "n8n")

      expect(token).to be_persisted
      expect(token.plaintext_token).to start_with("podi_")
      expect(token.token_digest).to eq(Digest::SHA256.hexdigest(token.plaintext_token))
      expect(described_class.find(token.id).plaintext_token).to be_nil
    end

    it "requires a name" do
      token = described_class.issue(user: admin, name: "")

      expect(token).not_to be_persisted
      expect(token.errors[:name]).to include("can't be blank")
    end
  end

  describe ".authenticate" do
    let!(:token) { described_class.issue(user: admin, name: "n8n") }

    it "finds the token for a valid plaintext" do
      expect(described_class.authenticate(token.plaintext_token)).to eq(token)
    end

    it "returns nil for an unknown token" do
      expect(described_class.authenticate("podi_unknown")).to be_nil
    end

    it "returns nil for a blank token" do
      expect(described_class.authenticate(nil)).to be_nil
    end

    it "returns nil when the user is no longer an admin" do
      admin.update!(admin: false)

      expect(described_class.authenticate(token.plaintext_token)).to be_nil
    end
  end

  describe "#record_usage" do
    let(:token) { described_class.issue(user: admin, name: "n8n") }

    it "stores when the token was used" do
      freeze_time do
        token.record_usage

        expect(token.reload.last_used_at).to eq(Time.current)
      end
    end

    it "writes at most once a minute" do
      token.record_usage
      first_use = token.reload.last_used_at

      travel 30.seconds do
        token.record_usage
        expect(token.reload.last_used_at).to eq(first_use)
      end
    end
  end

  it "is destroyed with its user" do
    described_class.issue(user: admin, name: "n8n")

    expect { admin.destroy }.to change(described_class, :count).by(-1)
  end
end
```

### 4c. Implement `app/models/api_token.rb`

```ruby
class ApiToken < ApplicationRecord
  PREFIX = "podi_".freeze
  USAGE_PRECISION = 1.minute

  belongs_to :user

  # Only set on the instance returned by .issue; never stored.
  attr_accessor :plaintext_token

  validates :name, presence: true
  validates :token_digest, presence: true, uniqueness: true

  def self.issue(user:, name:)
    plaintext = "#{PREFIX}#{SecureRandom.base58(43)}"
    create(user: user, name: name, token_digest: digest(plaintext), plaintext_token: plaintext)
  end

  # Returns nil unless the token exists and its user is still an admin.
  def self.authenticate(plaintext)
    return if plaintext.blank?

    token = includes(:user).find_by(token_digest: digest(plaintext))
    token if token&.user&.admin?
  end

  def self.digest(plaintext)
    Digest::SHA256.hexdigest(plaintext)
  end

  def record_usage
    return if last_used_at&.after?(USAGE_PRECISION.ago)

    update_column(:last_used_at, Time.current)
  end
end
```

`update_column` is deliberate: it skips validations and doesn't touch `updated_at`, because recording use
is bookkeeping, not an edit.

In `app/models/user.rb`:

```ruby
  has_many :api_tokens, dependent: :destroy
```

### 4d. Verify and commit

```sh
bin/rspec spec/models/api_token_spec.rb spec/models/user_spec.rb
git add db/migrate db/schema.rb app/models/api_token.rb app/models/user.rb spec/models/api_token_spec.rb
git commit -m "feat: add ApiToken model"
```

---

## Task 5: Admin UI for API Tokens

### 5a. Failing system spec: `spec/system/admin/api_tokens_spec.rb`

```ruby
require "capybara_helper"

describe "API tokens", type: :system do
  let!(:setting) { create(:setting) }
  let(:admin) { create(:user, :admin) }

  context "when logged in as admin" do
    before { login_as admin }

    it "creates a token and shows it once" do
      visit "/"
      click_on "API Tokens"
      click_on "Add"

      click_on "Create"
      expect(page).to have_content "Name can't be blank"

      fill_in "Name", with: "n8n publishing"
      click_on "Create"

      plaintext = find_by_id("api-token-plaintext").text
      expect(plaintext).to start_with("podi_")
      expect(ApiToken.authenticate(plaintext).name).to eq("n8n publishing")

      visit "/admin/api_tokens"
      expect(page).to have_content "n8n publishing"
      expect(page).to have_content "Never"
      expect(page).to have_no_content plaintext
    end

    it "revokes a token" do
      token = ApiToken.issue(user: admin, name: "old script")

      visit "/admin/api_tokens"
      within "#api-token-#{token.id}" do
        click_on "Revoke"
      end

      expect(page).to have_content "API token was revoked."
      expect(page).to have_no_content "old script"
      expect(ApiToken.exists?(token.id)).to be(false)
    end

    it "only lists the admin's own tokens" do
      other_admin = create(:user, :admin, email: "other@test.com")
      ApiToken.issue(user: other_admin, name: "someone else's")

      visit "/admin/api_tokens"

      expect(page).to have_no_content "someone else's"
    end
  end

  context "when logged in as a non-admin" do
    it "denies access" do
      login_as create(:user)

      visit "/admin/api_tokens"

      expect(page).to have_content "Access Denied"
    end
  end
end
```

### 5b. Routes

In `config/routes.rb`, inside `namespace :admin`:

```ruby
    resources :api_tokens, only: %w[index new create destroy]
```

### 5c. Controller: `app/controllers/admin/api_tokens_controller.rb`

```ruby
module Admin
  class ApiTokensController < BaseController
    def index
      @api_tokens = current_user.api_tokens.order(created_at: :desc)
    end

    def new
      @api_token = current_user.api_tokens.new
    end

    # Renders instead of redirecting: the plaintext token must not travel through the flash,
    # which is stored in the session cookie.
    def create
      @api_token = ApiToken.issue(user: current_user, name: api_token_params[:name])
      if @api_token.persisted?
        render :created
      else
        render :new, status: :unprocessable_content
      end
    end

    def destroy
      current_user.api_tokens.find(params[:id]).destroy!
      redirect_to admin_api_tokens_path, notice: "API token was revoked."
    end

    private

    def api_token_params
      params.require(:api_token).permit(:name)
    end
  end
end
```

`current_user.api_tokens.find` scopes `destroy` to the admin's own tokens. Another admin's token id gives
a 404.

### 5d. Views

`app/views/admin/api_tokens/index.html.haml`:

```haml
.site-section.bg-light
  .container
    .row
      .col-md-12
        %h1 API Tokens
        %p
          Tokens let scripts and AI agents create draft episodes through the API.
          Drafts stay unlisted until you tick "Active" on the episode.
        %table.table.table-striped.table-bordered
          %thead.table-dark
            %tr
              %th Name
              %th Created
              %th Last used
              %th
          %tbody
            - @api_tokens.each do |api_token|
              %tr{id: "api-token-#{api_token.id}"}
                %td= api_token.name
                %td= format_datetime api_token.created_at
                %td= format_datetime(api_token.last_used_at).presence || "Never"
                %td= button_to "Revoke", admin_api_token_path(api_token), method: :delete, class: "btn btn-danger", form: { data: { turbo_confirm: "Revoke this token? Anything using it stops working." } }
        = add_button new_admin_api_token_path
```

`app/views/admin/api_tokens/new.html.haml`. **`data: { turbo: false }` is required:** Turbo refuses a
`200` HTML response to a form POST (it expects a redirect), and `create` deliberately renders the token
page instead of redirecting.

```haml
.site-section.bg-light
  .container
    .row
      .col-md-12
        %h1 New API Token
        = simple_form_for([ :admin, @api_token ], html: { class: "form-horizontal", data: { turbo: false } }) do |f|
          = f.error_notification
          .form-inputs
            = f.input :name, hint: "Where the token is used, e.g. \"n8n publishing\""
          .form-actions
            = submit_button "Create"

        = back_button admin_api_tokens_path
```

`app/views/admin/api_tokens/created.html.haml`:

```haml
.site-section.bg-light
  .container
    .row
      .col-md-12
        %h1 API Token Created
        .alert.alert-warning Copy this token now. It will not be shown again.
        %pre#api-token-plaintext= @api_token.plaintext_token
        %p
          Send it as
          %code= "Authorization: Bearer <token>"
          (see docs/api.md).
        = back_button admin_api_tokens_path, "Back to API Tokens"
```

### 5e. Navigation

In `app/views/layouts/application.html.haml`, after the "Settings" link:

```haml
                = link_to "API Tokens", admin_api_tokens_path, class: "nav-link text-white"
```

**Watch out:** `spec/system/admin/setting_spec.rb` does `click_on "Setting"`, a partial match.
"API Tokens" doesn't contain "Setting", so it stays unambiguous. Run that spec anyway.

### 5f. Verify and commit

```sh
bin/rspec spec/system/admin/api_tokens_spec.rb spec/system/admin/setting_spec.rb
bin/rubocop app/controllers/admin/api_tokens_controller.rb spec/system/admin/api_tokens_spec.rb
git add config/routes.rb app/controllers/admin/api_tokens_controller.rb app/views/admin/api_tokens app/views/layouts/application.html.haml spec/system/admin/api_tokens_spec.rb
git commit -m "feat: manage API tokens in the admin"
```

---

## Task 6: API Base Controller, Authentication and Ping

### 6a. Failing request spec: `spec/requests/api/v1/ping_spec.rb`

```ruby
require "rails_helper"

RSpec.describe "API v1 ping", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:token) { ApiToken.issue(user: admin, name: "agent") }

  it "confirms a valid token and says whose it is" do
    get "/api/v1/ping", headers: { "Authorization" => "Bearer #{token.plaintext_token}" }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(
      "status" => "ok",
      "user" => { "email" => admin.email },
      "token" => { "name" => "agent" }
    )
  end

  it "records that the token was used" do
    get "/api/v1/ping", headers: { "Authorization" => "Bearer #{token.plaintext_token}" }

    expect(token.reload.last_used_at).to be_present
  end

  it "rejects a request without a token" do
    get "/api/v1/ping"

    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body).to eq("error" => "unauthorized", "message" => "Missing or invalid API token")
  end

  it "rejects an unknown token" do
    get "/api/v1/ping", headers: { "Authorization" => "Bearer podi_wrong" }

    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects the token of a user who is no longer an admin" do
    plaintext = token.plaintext_token
    admin.update!(admin: false)

    get "/api/v1/ping", headers: { "Authorization" => "Bearer #{plaintext}" }

    expect(response).to have_http_status(:unauthorized)
  end
end
```

### 6b. Routes

In `config/routes.rb`, after the `admin` namespace (and in any case **before** the catch-all
`get ":id"`):

```ruby
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      get "ping", to: "ping#show"
      resources :episodes, only: %w[create]
    end
  end
```

(The episodes route is used in Task 7. Adding it now is harmless.)

### 6c. Base controller: `app/controllers/api/v1/base_controller.rb`

It inherits from `ActionController::API`: no session, no CSRF, no cookies. Rails'
`authenticate_with_http_token` parses `Authorization: Bearer <token>` (and `Token <token>`).

```ruby
module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods

      before_action :authenticate_api_token!

      rescue_from ActionController::ParameterMissing do |error|
        render_error :bad_request, error: "bad_request", message: error.message
      end

      private

      attr_reader :current_api_token

      def current_user
        current_api_token.user
      end

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
```

### 6d. Ping: `app/controllers/api/v1/ping_controller.rb`

```ruby
module Api
  module V1
    class PingController < BaseController
      def show
        render json: { status: "ok", user: { email: current_user.email }, token: { name: current_api_token.name } }
      end
    end
  end
end
```

### 6e. Verify and commit

```sh
bin/rspec spec/requests/api/v1/ping_spec.rb
git add config/routes.rb app/controllers/api spec/requests/api
git commit -m "feat: add token-authenticated API ping"
```

---

## Task 7: `POST /api/v1/episodes`

**Rules this endpoint enforces:**
- Accepted fields: `title`, `description`, `nodes`, `published_on`, `audio` (required by the model), plus
  `chapter_marks`, `transcript`, `tag_list`, `image`. All under the `episode` key, as multipart.
- **Everything else is ignored**, especially `active`, `visible`, `number`, `slug`, `rss_feed`,
  `downloads_count`, `artwork_url`.
- The episode is always created with `active: false, visible: true`, and the number is always the next
  free one.

**Why `slice` before `permit`:** `config/initializers/strong_params.rb` makes unpermitted parameters
**raise in test** but only log in production. Without `slice`, a caller sending `active=true` would get
a 500 in specs and a silent drop in production, so the spec would test behaviour that production
doesn't have. Slicing first drops unknown keys the same way everywhere.

### 7a. Failing request spec: `spec/requests/api/v1/episodes_spec.rb`

```ruby
require "rails_helper"

RSpec.describe "API v1 episodes", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:headers) { { "Authorization" => "Bearer #{ApiToken.issue(user: admin, name: 'agent').plaintext_token}" } }
  let(:episode_params) do
    {
      title: "Neue Folge",
      description: "Wir reden über den Markt",
      nodes: "* Shownotes",
      published_on: "2026-10-20",
      audio: fixture_file_upload("test-001.mp3", "audio/mpeg")
    }
  end

  before { create(:setting) }

  describe "POST /api/v1/episodes" do
    it "creates an inactive draft with a preview link" do
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
        "published_on" => "2026-10-20",
        "active" => false,
        "visible" => true,
        "tags" => [],
        "preview_url" => "http://wartenberger.test.com/episodes/042-neue-folge"
      )
    end

    it "ignores attributes the API does not accept" do
      post "/api/v1/episodes",
           params: { episode: episode_params.merge(active: true, visible: false, number: 99, rss_feed: false) },
           headers: headers

      expect(response).to have_http_status(:created)
      expect(Episode.last).to have_attributes(active: false, visible: true, number: 1, rss_feed: true)
    end

    it "stores the optional fields" do
      post "/api/v1/episodes",
           params: { episode: episode_params.merge(
             chapter_marks: "00:00:01.000 Intro",
             transcript: "WEBVTT\n\n00:00:00.000 --> 00:00:02.000\nServus",
             tag_list: "Interview, Geschichte",
             image: fixture_file_upload("001-vorstellung.jpg", "image/jpeg")
           ) },
           headers: headers

      expect(response).to have_http_status(:created)
      episode = Episode.last
      expect(episode.chapter_marks).to eq("00:00:01.000 Intro")
      expect(episode.transcript).to start_with("WEBVTT")
      expect(episode.tags).to eq(%w[Interview Geschichte])
      expect(episode.image).to be_present
    end

    it "keeps the draft off the public pages but reachable by its preview link" do
      post "/api/v1/episodes", params: { episode: episode_params }, headers: headers

      get "/episodes"
      expect(response.body).not_to include("Neue Folge")

      get "/episodes.rss"
      expect(response.body).not_to include("Neue Folge")

      get "/episodes/001-neue-folge"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Neue Folge")
    end

    it "explains validation errors per field" do
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

    it "rejects audio that is not an mp3" do
      post "/api/v1/episodes",
           params: { episode: episode_params.merge(audio: fixture_file_upload("001-vorstellung.jpg", "audio/mpeg")) },
           headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["messages"]["audio"]).to eq([ "must be an MP3 file (audio/mpeg)" ])
    end

    it "answers 400 without the episode key" do
      post "/api/v1/episodes", params: { title: "Neue Folge" }, headers: headers

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["error"]).to eq("bad_request")
    end

    it "creates nothing without a valid token" do
      expect do
        post "/api/v1/episodes", params: { episode: episode_params }
      end.not_to change(Episode, :count)

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
```

Notes for this spec:
- `fixture_file_upload("test-001.mp3", …)` resolves against `spec/fixtures` (`config.fixture_paths` in
  `spec/rails_helper.rb`).
- Test URLs use `http://wartenberger.test.com` (`config.host_url` in `config/environments/test.rb`).
- `duration` is not asserted: it is `null` right after creation, because Active Storage analyzes the mp3
  in a background job.

### 7b. Controller: `app/controllers/api/v1/episodes_controller.rb`

```ruby
module Api
  module V1
    class EpisodesController < BaseController
      PERMITTED_ATTRIBUTES = %i[title description nodes published_on audio image chapter_marks transcript tag_list].freeze

      # Episodes created through the API are drafts: unlisted but reachable by link
      # until a human ticks "Active" in the admin.
      DRAFT_ATTRIBUTES = { active: false, visible: true }.freeze

      def create
        @episode = EpisodeCreator.call(episode_attributes: episode_params.merge(DRAFT_ATTRIBUTES))
        if @episode.persisted?
          render :show, status: :created, location: episode_url(@episode)
        else
          render_validation_errors
        end
      end

      private

      # Unknown keys are sliced away before permit so they are ignored the same way in every
      # environment (test raises on unpermitted parameters, production only logs them).
      def episode_params
        params.require(:episode).slice(*PERMITTED_ATTRIBUTES).permit(*PERMITTED_ATTRIBUTES)
      end

      def render_validation_errors
        render_error :unprocessable_content,
                     error: "validation_failed",
                     message: @episode.errors.full_messages.to_sentence,
                     messages: @episode.errors.to_hash
      end
    end
  end
end
```

`number` is deliberately not permitted, so `EpisodeCreator` always assigns the next number.

### 7c. View: `app/views/api/v1/episodes/show.json.jbuilder`

```ruby
json.episode do
  json.extract! @episode, :id, :number, :slug, :title, :published_on, :active, :visible, :tags, :duration
  json.preview_url episode_url(@episode)
end
```

jbuilder supports `ActionController::API` controllers out of the box. If `render :show` raises a
missing template error anyway, stop and investigate. **Don't** switch to `ActionController::Base`.

### 7d. Verify and commit

```sh
bin/rspec spec/requests/api/v1/episodes_spec.rb spec/requests/api/v1/ping_spec.rb
bin/rubocop app/controllers/api spec/requests/api
git add app/controllers/api/v1/episodes_controller.rb app/views/api spec/requests/api/v1/episodes_spec.rb
git commit -m "feat: create draft episodes via the API"
```

---

## Task 8: Rate Limits

**Rules:**
- At most **60 requests per minute per token** (stops a runaway agent).
- At most **10 failed authentications per minute per IP**. After that, the IP gets `429` **before** any
  token lookup, so guessing gets no feedback.

**Why not Rails' built-in `rate_limit`:** it captures its cache store when the class loads. Tests use
`:null_store` (`config/environments/test.rb`), which never counts, and the store can't be swapped per
spec afterwards. We also need a failure-only counter that `rate_limit` can't express. Two small
`Rails.cache.increment` calls read the cache at request time, cover both rules and are testable. In
production `Rails.cache` is Redis.

**Rack::Attack is not used for this:** it runs before the app, so it can't know whether authentication
failed.

### 8a. Failing request spec: `spec/requests/api/v1/rate_limiting_spec.rb`

```ruby
require "rails_helper"

RSpec.describe "API v1 rate limiting", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:headers) { { "Authorization" => "Bearer #{ApiToken.issue(user: admin, name: 'agent').plaintext_token}" } }

  # The test environment uses :null_store, which never counts.
  before { allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new) }

  it "allows 60 requests per minute per token" do
    60.times { get "/api/v1/ping", headers: headers }
    expect(response).to have_http_status(:ok)

    get "/api/v1/ping", headers: headers

    expect(response).to have_http_status(:too_many_requests)
    expect(response.parsed_body["error"]).to eq("rate_limited")
  end

  it "allows requests again after a minute" do
    61.times { get "/api/v1/ping", headers: headers }

    travel 61.seconds do
      get "/api/v1/ping", headers: headers
      expect(response).to have_http_status(:ok)
    end
  end

  it "blocks an IP after 10 failed authentications, even with a valid token" do
    10.times { get "/api/v1/ping", headers: { "Authorization" => "Bearer podi_wrong" } }
    expect(response).to have_http_status(:unauthorized)

    get "/api/v1/ping", headers: headers

    expect(response).to have_http_status(:too_many_requests)
  end

  it "does not block other IPs" do
    10.times { get "/api/v1/ping", headers: { "Authorization" => "Bearer podi_wrong" } }

    get "/api/v1/ping", headers: headers, env: { "REMOTE_ADDR" => "203.0.113.9" }

    expect(response).to have_http_status(:ok)
  end
end
```

### 8b. Implement in `Api::V1::BaseController`

Add constants and a second `before_action`, and extend `authenticate_api_token!`:

```ruby
      REQUESTS_PER_TOKEN_PER_MINUTE = 60
      FAILED_AUTHENTICATIONS_PER_IP_PER_MINUTE = 10

      before_action :authenticate_api_token!
      before_action :limit_requests_per_token
```

```ruby
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

      def failed_authentications_exceeded?
        Rails.cache.read(failed_authentications_key, raw: true).to_i >= FAILED_AUTHENTICATIONS_PER_IP_PER_MINUTE
      end

      def failed_authentications_key
        "api:failed-authentications:#{request.remote_ip}"
      end

      def render_rate_limited
        render_error :too_many_requests, error: "rate_limited", message: "Too many requests, retry in a minute"
      end
```

`raw: true` matters for Redis: `increment` stores a raw integer, which a normal `read` can't deserialize.
`MemoryStore` ignores the option.

### 8c. Verify and commit

```sh
bin/rspec spec/requests/api
git commit -am "feat: rate limit the API"
```

(Use `git add` for the new spec file first.)

---

## Task 9: `GET /api/v1/tags`

**Why:** the episode agent in the podcasts folder (`docs/plans/2026-10-06-episoden-agent.md` in the
Dropbox `podcasts/` folder) proposes tags for new episodes. Tags are not public anywhere (not in the RSS
feed, no tag route), so without this endpoint the agent can't see which tags exist and invents variants
("Musik", "Musiker", "Band") that split the episodes apart.

**Rules:**
- Token-authenticated through `Api::V1::BaseController`, with the same rate limits as every endpoint.
- Returns every distinct tag across **all** episodes, active or not, sorted alphabetically:
  `{ "tags": ["Geschichte", "Interview", "Musik"] }`. Draft tags count too: the agent should reuse a tag
  from an episode that is still in review.

### 9a. Failing model spec

Add to `spec/models/episode_spec.rb`:

```ruby
  describe ".all_tags" do
    it "lists every tag once, sorted" do
      create(:episode, tags: %w[Musik Interview])
      create(:episode, tags: %w[Geschichte Musik], active: false)

      expect(described_class.all_tags).to eq(%w[Geschichte Interview Musik])
    end

    it "is empty without tags" do
      create(:episode)

      expect(described_class.all_tags).to eq([])
    end
  end
```

Run `bin/rspec spec/models/episode_spec.rb` and confirm it fails with `NoMethodError`.

### 9b. Implement in `app/models/episode.rb`

Next to `self.next_number`:

```ruby
  def self.all_tags
    pluck(Arel.sql("DISTINCT unnest(tags)")).sort
  end
```

`unnest` turns the PostgreSQL array into one row per tag. Run the model spec green.

### 9c. Failing request spec: `spec/requests/api/v1/tags_spec.rb`

```ruby
require "rails_helper"

RSpec.describe "API v1 tags", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:token) { ApiToken.issue(user: admin, name: "agent") }

  context "with a valid token" do
    it "lists every tag in use", :aggregate_failures do
      create(:episode, tags: %w[Musik Interview])

      get "/api/v1/tags", headers: { "Authorization" => "Bearer #{token.plaintext_token}" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("tags" => %w[Interview Musik])
    end
  end

  context "without a token" do
    it "answers unauthorized" do
      get "/api/v1/tags"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
```

Run it and confirm it fails with a routing error.

### 9d. Route, controller, view

`config/routes.rb`, inside `namespace :v1`:

```ruby
      resources :tags, only: %w[index]
```

`app/controllers/api/v1/tags_controller.rb`:

```ruby
module Api
  module V1
    class TagsController < BaseController
      def index
        @tags = Episode.all_tags
      end
    end
  end
end
```

`app/views/api/v1/tags/index.json.jbuilder`:

```ruby
json.tags @tags
```

### 9e. Verify and commit

```sh
bin/rspec spec/models/episode_spec.rb spec/requests/api
bin/rubocop
git add spec/requests/api/v1/tags_spec.rb app/controllers/api/v1/tags_controller.rb app/views/api/v1/tags
git commit -am "feat: add GET /api/v1/tags"
```

---

## Task 10: Documentation

### 10a. `docs/api.md`

The reader is an **AI agent** with a shell, which will follow it literally. Write it precisely. Content:

````markdown
# Podi API v1

The Podi API lets a script or an AI agent create **draft** podcast episodes. A draft is never public on
its own: it stays off the homepage, the episode list, search and the RSS feed until a human approves it
in the admin. This is expected behaviour, not an error.

Base URL: `https://www.wartenberger.de/api/v1`

## Authentication

An admin creates a token under **Admin → API Tokens**. It is shown once. Send it with every request:

    Authorization: Bearer podi_…

Check a token:

    curl -s https://www.wartenberger.de/api/v1/ping -H "Authorization: Bearer $PODI_TOKEN"

`200` response:

    { "status": "ok", "user": { "email": "admin@example.com" }, "token": { "name": "n8n publishing" } }

## Create a draft episode

`POST /episodes` as `multipart/form-data`. All fields are nested under `episode[...]`.

| Field | Required | Format |
|---|---|---|
| `episode[audio]` | yes | MP3 file (`audio/mpeg`). Other formats are rejected |
| `episode[title]` | yes | Text, unique across all episodes |
| `episode[description]` | yes | Markdown |
| `episode[nodes]` | yes | Show notes, Markdown |
| `episode[published_on]` | yes | Date, `YYYY-MM-DD` |
| `episode[chapter_marks]` | no | One chapter per line: `HH:MM:SS.mmm Title`, e.g. `00:00:41.018 Intro` |
| `episode[transcript]` | no | WebVTT content (starts with `WEBVTT`) |
| `episode[tag_list]` | no | Comma-separated, e.g. `Interview, Geschichte` |
| `episode[image]` | no | Cover image file: JPEG, PNG or WebP |

Any other field (for example `active`, `visible`, `number`, `slug`) is ignored. The episode number is
always the next free number.

    curl -s https://www.wartenberger.de/api/v1/episodes \
      -H "Authorization: Bearer $PODI_TOKEN" \
      -F "episode[title]=Folge über den Markt" \
      -F "episode[description]=Wir reden über den Markt." \
      -F "episode[nodes]=* Link 1" \
      -F "episode[published_on]=2026-10-20" \
      -F "episode[tag_list]=Interview, Markt" \
      -F "episode[audio]=@folge.mp3;type=audio/mpeg"

`201 Created`, with a `Location` header pointing to the preview page:

    { "episode": { "id": 87, "number": 42, "slug": "042-folge-uber-den-markt",
      "title": "Folge über den Markt", "published_on": "2026-10-20",
      "active": false, "visible": true, "tags": ["Interview", "Markt"], "duration": null,
      "preview_url": "https://www.wartenberger.de/episodes/042-folge-uber-den-markt" } }

- `active: false` means waiting for human approval. Share `preview_url` with the person who approves it.
- `duration` is `null` at first; it is filled in once the audio has been analysed.

## List tags

`GET /tags` returns every tag used by any episode, drafts included, sorted alphabetically. Reuse these
tags when you set `episode[tag_list]` instead of inventing variants of the same topic.

    curl -s https://www.wartenberger.de/api/v1/tags -H "Authorization: Bearer $PODI_TOKEN"

`200` response:

    { "tags": ["Geschichte", "Interview", "Musik"] }

## Errors

Every error has the same shape: `error` (a machine-readable code), and `message` and/or `messages`.

| Status | `error` | Meaning | What to do |
|---|---|---|---|
| 400 | `bad_request` | Fields not nested under `episode[...]` | Fix the request shape |
| 401 | `unauthorized` | Token missing, wrong or revoked | Ask an admin for a valid token; don't retry |
| 422 | `validation_failed` | A field is invalid; `messages` lists them per field | Fix the listed fields and send again |
| 429 | `rate_limited` | More than 60 requests a minute, or 10 failed logins a minute from your IP | Wait one minute |

    { "error": "validation_failed",
      "message": "Title has already been taken and Audio must be an MP3 file (audio/mpeg)",
      "messages": { "title": ["has already been taken"], "audio": ["must be an MP3 file (audio/mpeg)"] } }

If `messages.number` says "has already been taken", another episode was created at the same moment.
Retry the same request.

## Compatibility

v1 may gain new fields in responses and new optional request fields. Don't treat unknown response fields
as errors. Breaking changes get a new version path (`/api/v2`).
````

Before committing, **check that the slug in the example matches reality**: `"Folge über den Markt"`
gives `042-folge-uber-den-markt` or `042-folge-ueber-den-markt`, depending on what Task 1a found. Fix
the example so it's true.

### 10b. README

Add a short section to `README.md`:

```markdown
## API

Admins create API tokens under Admin → API Tokens. The token-authenticated API creates draft episodes
that stay unlisted until approved in the admin. See [docs/api.md](docs/api.md).
```

### 10c. AGENTS.md

Add under "Architecture and Conventions" in `AGENTS.md`:

```markdown
### External API

`/api/v1` (`app/controllers/api/v1/`) inherits from `ActionController::API` and authenticates with
`ApiToken` (`Authorization: Bearer`, only the SHA-256 digest is stored, tokens only work for admins).
Episodes created through it are always `active: false, visible: true` drafts: the API controller sets
this, `EpisodeCreator` (shared with the admin) doesn't know about it. Documentation: `docs/api.md`.
```

Also update the "Episode Visibility" section for the changes in Tasks 1 and 3:
- Under the table, add: "`active` defaults to `false`: every new episode, from the admin or the API,
  is a draft until someone ticks "Active". The admin index marks drafts with a "Draft" badge."
- In "Other `Episode` details", the slug bullet now reads: "`slug` is built by `Episode#build_slug` from
  the zero-padded number and the title (`"001 Title".parameterize(locale: :de)`), and new episodes are
  created through `EpisodeCreator`, which also assigns `Episode.next_number`."

### 10d. Commit

```sh
git add docs/api.md README.md AGENTS.md
git commit -m "docs: document the episodes API"
```

---

## Task 11: Final Checks, PR and Rollout

### 11a. Local checks

```sh
bin/rubocop
bin/brakeman --no-pager
bin/rspec spec/models spec/services spec/requests spec/system/admin/episodes_spec.rb spec/system/admin/api_tokens_spec.rb spec/system/admin/setting_spec.rb spec/system/episodes_spec.rb spec/system/welcome_spec.rb
```

All must be clean. Any Brakeman warning gets fixed or explained to Michael; don't ignore it.

### 11b. Pull request

Push `external_api` and open a PR against `master` (use the `create_pullrequest` skill). The description
explains the story (AI agents create drafts, a human approves), how to review it (start with
`Api::V1::BaseController`, `Api::V1::EpisodesController` and `ApiToken`; `EpisodeCreator` is an
extraction), and the design choices (digest-only tokens, controller-based rate limits instead of
Rack::Attack, `slice` before `permit`, the `active` default change). CI runs the full suite.

### 11c. Pre-flight before merging (production data)

The MP3 validation must not lock existing episodes. In production:

```sh
bin/kamal console
```

```ruby
ActiveStorage::Attachment.where(record_type: "Episode", name: "audio")
  .joins(:blob).where.not(active_storage_blobs: { content_type: "audio/mpeg" })
  .pluck(:record_id, "active_storage_blobs.content_type")
```

It must return `[]`. If it doesn't, **stop and discuss with Michael** before merging.

Michael ran it on 2026-10-06 and it returned `[]`. Run it again before merging only if episodes with
non-MP3 audio might have been uploaded since.

### 11d. Smoke test after deploy

1. Admin → API Tokens → create "smoke test" and copy the token.
2. `curl -s https://www.wartenberger.de/api/v1/ping -H "Authorization: Bearer $TOKEN"` → `200`.
3. Create an episode with the `curl` from `docs/api.md` and a real short mp3 → `201`.
4. Check: the homepage, `/episodes` and `/episodes.rss` don't show it; `preview_url` plays it; the admin
   index shows "Draft".
5. Delete the test episode (Rails console, since the admin has no delete) and revoke the token.
6. 11 requests with a wrong token → the 11th is `429` (proves Redis counting works with `raw: true`).
````
