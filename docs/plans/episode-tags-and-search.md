# Episode Tags & Live Search — Implementation Plan

## Overview

Two features built in sequence:

1. **Episode Tags** — Free-form tags stored as a PostgreSQL array on the `episodes` table. Editable via the admin form. Not displayed publicly (yet).
2. **Live Search** — A lens icon in the navbar that expands into a search input. As the user types, the main page content is replaced (via Turbo Frame) with compact search results. Searches across episode `title`, `description`, and `tags`.

**Branch name:** `search_functionality` (already exists — work here)

---

## Prerequisites — Read These First

Before writing any code, read and understand these files:

| File | Why |
|------|-----|
| `app/models/episode.rb` | The model you'll modify. Note `ATTRIBUTES`, scopes, validations |
| `app/controllers/episodes_controller.rb` | Public episodes controller — you'll add search here |
| `app/controllers/admin/episodes_controller.rb` | Admin controller — you'll modify strong params here |
| `app/views/admin/episodes/_form.html.haml` | Admin form — you'll add the tags field here |
| `app/views/layouts/application.html.haml` | Main layout — you'll add the search icon + input here |
| `app/views/episodes/index.html.haml` | Episodes listing — you'll wrap content in a Turbo Frame |
| `app/views/shared/_episode.html.haml` | Episode card partial — for reference on existing patterns |
| `app/presenters/episode_presenter.rb` | Presenter pattern — for reference |
| `app/presenters/application_presenter.rb` | Base presenter — `SimpleDelegator` pattern |
| `app/javascript/application.js` | JS entry point — you'll add a Stimulus controller import |
| `config/importmap.rb` | Importmap pins — you'll pin Stimulus here |
| `config/routes.rb` | Routes — you'll add a search route |
| `spec/models/episode_spec.rb` | Existing model specs — follow this pattern |
| `spec/system/episodes_spec.rb` | Existing system specs — follow this pattern |
| `spec/system/admin/episodes_spec.rb` | Admin system specs — follow this pattern |
| `spec/factories/episodes.rb` | Episode factory — you'll add `tags` here |
| `spec/capybara_helper.rb` | System test setup — `driven_by :rack_test` by default, `:js` tag switches to Selenium |

---

## Conventions You Must Follow

- **Template engine:** HAML (never ERB)
- **Strings:** Always double quotes (`"hello"`, not `'hello'`)
- **Testing:** TDD — write the failing test first, then make it pass
- **Commits:** Conventional commits (`feat:`, `test:`, `refactor:`), imperative mood, frequent and atomic
- **Views:** Use presenters for view logic, not helpers in controllers
- **I18n:** Use full key paths (`t("episodes.search.placeholder")`), never lazy lookup (`.placeholder`)
- **Strong params:** This project uses `params.require(:episode).permit(...)` (not Rails 8 `params.expect` — match the existing pattern)
- **Forms:** The admin form uses SimpleForm (`= f.input :field_name`)
- **System tests:** Default driver is `rack_test`. Add `js: true` metadata for tests that need JavaScript (Stimulus, Turbo Frames). JS tests use Selenium with headless Chrome and are slower — only use when necessary.
- **Search requires JS:** Live search uses a Stimulus controller for debounce and a Turbo Frame for replacing content. System tests for search behavior MUST use `js: true`.

---

## Task 1: Add `tags` Column to Episodes

**Goal:** Add a PostgreSQL text array column to store free-form tags.

### 1a. Generate the migration

```bash
rails g migration AddTagsToEpisodes
```

Edit the generated migration file in `db/migrate/`:

```ruby
class AddTagsToEpisodes < ActiveRecord::Migration[8.1]
  def change
    add_column :episodes, :tags, :text, array: true, default: []
    add_index :episodes, :tags, using: :gin
  end
end
```

**Why a GIN index:** PostgreSQL GIN indexes make array containment queries fast (e.g., "find all episodes with tag X"). Even though we're not querying by individual tag yet, it costs nothing now and avoids a future migration.

**Why `text` array, not `string`:** In PostgreSQL, `text` and `string`/`varchar` have identical performance. `text` avoids arbitrary length limits.

Run the migration:

```bash
rails db:migrate
```

Verify `db/schema.rb` was updated — it should show `t.text "tags", default: [], array: true` in the episodes table.

### 1b. Update the Episode model

**File:** `app/models/episode.rb`

Add `tag_list` to the `ATTRIBUTES` array (not `tags` — we use a virtual attribute for the comma-separated form input):

```ruby
ATTRIBUTES = %w[
  title
  description
  published_on
  nodes
  number
  active
  image
  chapter_marks
  transcript
  artwork_url
  audio
  visible
  rss_feed
  tag_list
].freeze
```

Add the virtual attribute below the `ATTRIBUTES` constant, before `to_param`:

```ruby
def tag_list
  tags.join(", ")
end

def tag_list=(value)
  self.tags = value.to_s.split(",").map(&:strip).reject(&:blank?)
end
```

**How it works:** The form sends a comma-separated string like `"Interview, Geschichte"`. The setter splits it into `["Interview", "Geschichte"]` and stores it in the `tags` array column. The getter joins the array back for display in the form.

### 1c. Update the factory

**File:** `spec/factories/episodes.rb`

Add `tags` with a default value inside the `factory :episode` block:

```ruby
tags { [] }
```

### 1d. Write the model spec (TDD)

**File:** `spec/models/episode_spec.rb`

Add a new `describe` block after the existing `.published` block:

```ruby
describe "#tag_list" do
  it "returns tags as comma-separated string" do
    episode = build(:episode, tags: ["Interview", "Geschichte"])

    expect(episode.tag_list).to eq("Interview, Geschichte")
  end

  it "returns empty string when no tags" do
    episode = build(:episode, tags: [])

    expect(episode.tag_list).to eq("")
  end
end

describe "#tag_list=" do
  it "splits comma-separated string into tags array" do
    episode = build(:episode)
    episode.tag_list = "Interview, Geschichte, Technik"

    expect(episode.tags).to eq(["Interview", "Geschichte", "Technik"])
  end

  it "strips whitespace from tags" do
    episode = build(:episode)
    episode.tag_list = "  Interview ,  Geschichte  "

    expect(episode.tags).to eq(["Interview", "Geschichte"])
  end

  it "rejects blank tags" do
    episode = build(:episode)
    episode.tag_list = "Interview,,, Geschichte,"

    expect(episode.tags).to eq(["Interview", "Geschichte"])
  end

  it "handles nil" do
    episode = build(:episode)
    episode.tag_list = nil

    expect(episode.tags).to eq([])
  end
end
```

**Run:** `bundle exec rspec spec/models/episode_spec.rb`

All tests should pass after implementing 1b. If they don't, fix the model code until they do.

### 1e. Commit

```
git add db/migrate/*_add_tags_to_episodes.rb db/schema.rb app/models/episode.rb spec/models/episode_spec.rb spec/factories/episodes.rb
git commit -m "feat: add tags column to episodes as PostgreSQL text array"
```

---

## Task 2: Add Tags to the Admin Form

**Goal:** Admin can enter and edit tags via a comma-separated text input.

### 2a. Write the system spec first (TDD)

**File:** `spec/system/admin/episodes_spec.rb`

Add a new test inside the `"when logged in as admin"` context:

```ruby
it "edits tags on an episode" do
  episode = create(:episode, title: "Tag Test", number: 1, tags: ["Interview"])

  visit "/admin/episodes"

  within "#episode-#{episode.id}" do
    click_on "Edit"
  end

  expect(page).to have_field("Tag list", with: "Interview")

  fill_in "Tag list", with: "Geschichte, Technik, Interview"
  click_on "Save"

  expect(page).to have_content "Episode was successfully updated."
  expect(episode.reload.tags).to eq(["Geschichte", "Technik", "Interview"])
end
```

**Run:** `bundle exec rspec spec/system/admin/episodes_spec.rb` — this test should FAIL because the form field doesn't exist yet.

### 2b. Add the field to the admin form

**File:** `app/views/admin/episodes/_form.html.haml`

Add this line after the `transcript` input and before the `image` hidden field:

```haml
= f.input :tag_list, hint: "Comma-separated list of tags (e.g. Interview, Geschichte, Technik)"
```

**Why this works:** SimpleForm calls `episode.tag_list` to get the value and `episode.tag_list=` to set it. The virtual attribute handles the conversion.

### 2c. Run the spec again

```bash
bundle exec rspec spec/system/admin/episodes_spec.rb
```

It should pass now. If it doesn't, check:
- Is `tag_list` in the `ATTRIBUTES` array? (strong params)
- Does the virtual attribute getter/setter work?

### 2d. Run the full admin spec suite to ensure nothing broke

```bash
bundle exec rspec spec/system/admin/episodes_spec.rb
```

All existing tests must still pass. The existing "create" and "edit" tests don't fill in the tags field, so they should work unchanged.

### 2e. Commit

```
git add app/views/admin/episodes/_form.html.haml spec/system/admin/episodes_spec.rb
git commit -m "feat: add tag editing to admin episode form"
```

---

## Task 3: Add the Search Route and Controller Action

**Goal:** A `GET /episodes/search` endpoint that accepts a `q` parameter and returns matching published episodes.

### 3a. Write the request spec first (TDD)

**Create file:** `spec/requests/search_episodes_spec.rb`

```ruby
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

    it "returns empty state when no matches" do
      get "/episodes/search", params: { q: "nonexistent" }

      expect(response).to have_http_status(:ok)
    end

    it "returns empty state when query is blank" do
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
```

**Run:** `bundle exec rspec spec/requests/search_episodes_spec.rb` — should FAIL (no route).

### 3b. Add the route

**File:** `config/routes.rb`

Add a search route as a collection action on episodes. Place it ABOVE the existing `resources :episodes` line (routes are matched top-to-bottom; if you put it below, `/episodes/search` would match `episodes#show` with `slug: "search"`):

```ruby
get "episodes/search", to: "episodes#search", as: :search_episodes

resources :episodes, only: %i[show index], param: :slug
```

### 3c. Add the search scope to Episode model

**File:** `app/models/episode.rb`

Add a new scope after the existing `visible` scope:

```ruby
scope :search, ->(query) {
  return none if query.blank?

  where(
    "title ILIKE :q OR description ILIKE :q OR :q = ANY(tags)",
    q: "%#{sanitize_sql_like(query)}%"
  ).or(
    where("EXISTS (SELECT 1 FROM unnest(tags) AS tag WHERE tag ILIKE :q)", q: "%#{sanitize_sql_like(query)}%")
  )
}
```

**Wait — that's getting complex.** Let's simplify. Use a straightforward ILIKE approach with `array_to_string` for tags:

```ruby
scope :search, ->(query) {
  return none if query.blank?

  sanitized = "%#{sanitize_sql_like(query)}%"
  where(
    "title ILIKE :q OR description ILIKE :q OR array_to_string(tags, ',') ILIKE :q",
    q: sanitized
  )
}
```

**How this works:**
- `ILIKE` is PostgreSQL case-insensitive pattern matching
- `sanitize_sql_like` escapes `%` and `_` in user input to prevent wildcard injection
- `array_to_string(tags, ',')` converts the array to a string so ILIKE works against tag values
- `return none` on blank query avoids returning all results

### 3d. Write the model spec for the search scope

**File:** `spec/models/episode_spec.rb`

Add after the existing `describe ".published"` block:

```ruby
describe ".search" do
  it "finds episodes by title" do
    episode = create(:episode, title: "Fahrrad Geschichte", number: 1)
    create(:episode, title: "Soli Wartenberg", number: 2)

    expect(Episode.search("Fahrrad")).to eq([episode])
  end

  it "finds episodes by description" do
    episode = create(:episode, title: "Episode 1", number: 1, description: "About cycling")
    create(:episode, title: "Episode 2", number: 2, description: "About cooking")

    expect(Episode.search("cycling")).to eq([episode])
  end

  it "finds episodes by tag" do
    episode = create(:episode, title: "Episode 1", number: 1, tags: ["Interview", "Technik"])
    create(:episode, title: "Episode 2", number: 2, tags: ["Geschichte"])

    expect(Episode.search("Interview")).to eq([episode])
  end

  it "is case-insensitive" do
    episode = create(:episode, title: "Fahrrad Geschichte", number: 1)

    expect(Episode.search("fahrrad")).to eq([episode])
  end

  it "returns none for blank query" do
    create(:episode, number: 1)

    expect(Episode.search("")).to be_empty
    expect(Episode.search(nil)).to be_empty
  end
end
```

**Run:** `bundle exec rspec spec/models/episode_spec.rb` — should pass after 3c is implemented.

### 3e. Add the search action to the controller

**File:** `app/controllers/episodes_controller.rb`

Add a `search` action:

```ruby
def search
  @query = params[:q].to_s.strip
  episodes = Episode.published.search(@query)
  @episodes = EpisodePresenter.wrap(episodes)
end
```

### 3f. Create the search results view

**Create file:** `app/views/episodes/search.html.haml`

```haml
= turbo_frame_tag "search_results" do
  - if @query.present?
    .container-fluid
      .row.mt-3.mb-3.justify-content-center
        .col-md-8
          - if @episodes.any?
            %p.text-muted
              = t("episodes.search.results_count", count: @episodes.size, query: @query)
            - @episodes.each do |episode|
              = render "shared/search_result", episode: episode
          - else
            %p.text-muted
              = t("episodes.search.no_results", query: @query)
```

### 3g. Create the search result partial

**Create file:** `app/views/shared/_search_result.html.haml`

This is the compact result format — title, episode number, date, and a description snippet:

```haml
.search-result.mb-3.p-3.bg-white.border.rounded
  %h5.mb-1
    = link_to episode.title, episode.episonde_url
  %small.text-muted
    = "#{t("episodes.search.episode")} #{episode.number}"
    &#183;
    = episode.published_on
  %p.mb-0.mt-1.text-truncate
    = truncate(strip_tags(episode.description), length: 200)
```

### 3h. Add I18n translations

**File:** `config/locales/de.yml` (or wherever the German locale file is — check `config/locales/` for existing structure)

Add under the appropriate key:

```yaml
de:
  episodes:
    search:
      placeholder: "Episoden durchsuchen..."
      results_count:
        one: "1 Ergebnis für \"%{query}\""
        other: "%{count} Ergebnisse für \"%{query}\""
      no_results: "Keine Ergebnisse für \"%{query}\""
      episode: "Episode"
```

Also add English translations in `config/locales/en.yml`:

```yaml
en:
  episodes:
    search:
      placeholder: "Search episodes..."
      results_count:
        one: "1 result for \"%{query}\""
        other: "%{count} results for \"%{query}\""
      no_results: "No results for \"%{query}\""
      episode: "Episode"
```

**Check first:** Look at `config/locales/` to see how existing translations are organized. Match that structure.

### 3i. Run the request spec

```bash
bundle exec rspec spec/requests/search_episodes_spec.rb
```

All tests should pass. Fix any failures before continuing.

### 3j. Commit

```
git add config/routes.rb app/models/episode.rb spec/models/episode_spec.rb app/controllers/episodes_controller.rb app/views/episodes/search.html.haml app/views/shared/_search_result.html.haml config/locales/ spec/requests/search_episodes_spec.rb
git commit -m "feat: add episode search by title, description, and tags"
```

---

## Task 4: Add the Search UI to the Navbar

**Goal:** A lens icon in the navbar that expands into a search input. Typing triggers a live search via Turbo Frame.

### 4a. Pin Stimulus in importmap

**File:** `config/importmap.rb`

Stimulus is required for the debounce controller. Add these pins:

```ruby
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
```

**Check first:** Run `bin/importmap audit` or look in `vendor/javascript/` to see if Stimulus is already vendored. If the pins already exist, skip this step.

### 4b. Set up Stimulus in application.js

**File:** `app/javascript/application.js`

Add Stimulus initialization. The file should become:

```javascript
import "@hotwired/turbo-rails"
import "bootstrap"
import { Application } from "@hotwired/stimulus"
import SearchController from "controllers/search_controller"

const application = Application.start()
application.register("search", SearchController)

document.addEventListener("turbo:load", () => {
  document.querySelectorAll("[data-bs-toggle='tooltip']").forEach((el) => {
    new bootstrap.Tooltip(el)
  })
})
```

Update `config/importmap.rb` to pin the controllers directory:

```ruby
pin_all_from "app/javascript/controllers", under: "controllers"
```

### 4c. Create the Stimulus search controller

**Create file:** `app/javascript/controllers/search_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "form"]

  toggle() {
    this.inputTarget.classList.toggle("d-none")
    if (!this.inputTarget.classList.contains("d-none")) {
      this.inputTarget.querySelector("input").focus()
    }
  }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.formTarget.requestSubmit()
    }, 300)
  }

  close(event) {
    if (!this.element.contains(event.target)) {
      this.inputTarget.classList.add("d-none")
    }
  }
}
```

**How it works:**
- `toggle()` — shows/hides the search input, focuses it when shown
- `search()` — debounces 300ms then submits the form (Turbo handles the frame update)
- `close()` — hides the input when clicking outside

### 4d. Add the search icon and input to the navbar

**File:** `app/views/layouts/application.html.haml`

Wrap the main content area in a Turbo Frame so search results can replace it. Find the `%main` section and modify it:

**Before (existing code around line 79):**
```haml
    %main
      .container-fluid

        .content
          = yield
```

**After:**
```haml
    %main
      .container-fluid
        = turbo_frame_tag "search_results" do
          .content
            = yield
```

Now add the search UI in the navbar. Find the `%ul.navbar-nav.ms-auto` block (line 62) and add a search item as the FIRST `%li` inside it:

```haml
          %ul.navbar-nav.ms-auto
            %li.nav-item{"data-controller" => "search", "data-action" => "click@window->search#close"}
              %button.btn.nav-link.text-white{"data-action" => "search#toggle", "aria-label" => "Search"}
                %i.fas.fa-search
              .d-none{"data-search-target" => "input"}
                = form_with url: search_episodes_path, method: :get, data: { search_target: "form", turbo_frame: "search_results" } do |f|
                  = f.search_field :q, class: "form-control form-control-sm", placeholder: t("episodes.search.placeholder"), data: { action: "input->search#search" }, autocomplete: "off"
            %li.nav-item
              %a.text-white.nav-link{href: episodes_path} Episoden
```

**Key details:**
- `fa-search` is from Font Awesome (already in the project — check the footer icons)
- `data-turbo-frame="search_results"` tells Turbo to replace the frame with that ID
- `data-action="input->search#search"` fires on every keystroke
- The form submits to `GET /episodes/search` with parameter `q`

### 4e. Add minimal CSS for the search input

**Find the main stylesheet** — check `app/assets/stylesheets/` for the application SCSS file. Add:

```scss
// Navbar search
.navbar .search-result {
  transition: all 0.2s ease;
}
```

The search input likely needs no custom CSS since Bootstrap's `form-control-sm` handles sizing. If the inline display looks off, add:

```scss
.navbar [data-search-target="input"] {
  min-width: 200px;
}
```

### 4f. Write the system spec (TDD)

**File:** `spec/system/episodes_spec.rb`

Add a new context block. **This test needs `js: true`** because it relies on Stimulus (JavaScript) for the toggle and live search behavior:

```ruby
context "search", js: true do
  it "searches episodes by typing in the navbar" do
    create(:episode, title: "Fahrrad Geschichte", number: 1, description: "About cycling in Wartenberg")
    create(:episode, title: "Soli Wartenberg", number: 2, description: "About solidarity")

    visit "/episodes"

    find("button[aria-label='Search']").click
    fill_in "q", with: "Fahrrad"

    expect(page).to have_content("Fahrrad Geschichte")
    expect(page).to have_no_content("Soli Wartenberg")
  end

  it "shows no results message for unmatched query" do
    visit "/episodes"

    find("button[aria-label='Search']").click
    fill_in "q", with: "nonexistent"

    expect(page).to have_content(I18n.t("episodes.search.no_results", query: "nonexistent"))
  end

  it "finds episodes by tag" do
    create(:episode, title: "Tagged Episode", number: 1, tags: ["Technik"])
    create(:episode, title: "Other Episode", number: 2)

    visit "/episodes"

    find("button[aria-label='Search']").click
    fill_in "q", with: "Technik"

    expect(page).to have_content("Tagged Episode")
    expect(page).to have_no_content("Other Episode")
  end
end
```

**Run:** `bundle exec rspec spec/system/episodes_spec.rb`

The non-JS tests should still pass. The JS tests will exercise the full Stimulus + Turbo Frame flow.

### 4g. Commit

```
git add config/importmap.rb app/javascript/ app/views/layouts/application.html.haml spec/system/episodes_spec.rb
git commit -m "feat: add live search UI with Stimulus controller and Turbo Frame"
```

---

## Task 5: Final Verification

### 5a. Run the full test suite

```bash
bundle exec rspec
```

Every test must pass — both new and existing. If anything broke, fix it before proceeding.

### 5b. Manual smoke test

1. Start the dev server: `rails s`
2. Visit the homepage — everything should look normal
3. Click the search icon in the navbar — input should appear
4. Type a partial episode title — results should replace the page content
5. Clear the search — page should show normal content
6. Go to admin, edit an episode, add some tags, save — tags should persist
7. Search for one of those tags — the episode should appear in results

### 5c. Run RuboCop

```bash
bundle exec rubocop --autocorrect
```

Fix any offenses, then commit:

```
git add -A
git commit -m "refactor: fix rubocop offenses"
```

### 5d. Final commit / PR readiness

At this point the branch `search_functionality` should have these commits:

1. `feat: add tags column to episodes as PostgreSQL text array`
2. `feat: add tag editing to admin episode form`
3. `feat: add episode search by title, description, and tags`
4. `feat: add live search UI with Stimulus controller and Turbo Frame`
5. `refactor: fix rubocop offenses` (if needed)

---

## File Change Summary

| File | Action | Task |
|------|--------|------|
| `db/migrate/XXX_add_tags_to_episodes.rb` | Create | 1 |
| `db/schema.rb` | Auto-updated by migration | 1 |
| `app/models/episode.rb` | Edit — add `tag_list` to ATTRIBUTES, add virtual attribute, add `search` scope | 1, 3 |
| `spec/models/episode_spec.rb` | Edit — add `#tag_list`, `#tag_list=`, `.search` specs | 1, 3 |
| `spec/factories/episodes.rb` | Edit — add `tags` attribute | 1 |
| `app/views/admin/episodes/_form.html.haml` | Edit — add tag_list input | 2 |
| `spec/system/admin/episodes_spec.rb` | Edit — add tag editing test | 2 |
| `config/routes.rb` | Edit — add search route | 3 |
| `app/controllers/episodes_controller.rb` | Edit — add `search` action | 3 |
| `app/views/episodes/search.html.haml` | Create | 3 |
| `app/views/shared/_search_result.html.haml` | Create | 3 |
| `config/locales/de.yml` | Edit — add search translations | 3 |
| `config/locales/en.yml` | Edit — add search translations | 3 |
| `spec/requests/search_episodes_spec.rb` | Create | 3 |
| `config/importmap.rb` | Edit — pin Stimulus + controllers | 4 |
| `app/javascript/application.js` | Edit — initialize Stimulus | 4 |
| `app/javascript/controllers/search_controller.js` | Create | 4 |
| `app/views/layouts/application.html.haml` | Edit — add search icon, Turbo Frame wrapper | 4 |
| `spec/system/episodes_spec.rb` | Edit — add search system specs | 4 |
| `app/assets/stylesheets/` | Edit — optional search CSS | 4 |

---

## Troubleshooting

**"undefined method `tag_list`"** — Check that `tag_list` is in `Episode::ATTRIBUTES` and the virtual attribute methods exist on the model.

**Search returns no results** — Check that test episodes are `published` (active, visible, past `published_on`). The search chains `.published.search(query)`.

**Turbo Frame doesn't update** — The `turbo_frame_tag` ID must match exactly between `search.html.haml` (`"search_results"`) and `application.html.haml` (`"search_results"`). Also check that the form has `data: { turbo_frame: "search_results" }`.

**Stimulus controller doesn't fire** — Check the importmap pins are correct, `application.js` registers the controller, and the `data-controller="search"` attribute is on the right DOM element.

**System tests with `js: true` fail** — Make sure Chrome/Chromium is installed. Check `spec/capybara_helper.rb` for driver config. Run with `SELENIUM_BROWSER=chrome` if headless doesn't work.

**`sanitize_sql_like` not found** — It's a class method. Call it as `self.class.sanitize_sql_like(query)` if used in an instance context, or just use it inside the scope lambda where `self` is the class.
