# Feed check fixes (issue #220)

Implementation plan for https://github.com/stereosupersonic/podi/issues/220. It replaces the checklist
from PR #219, which is closed in favour of this plan.

## Background

Running the public feed (`https://www.wartenberger.de/episodes.rss`) through the W3C feed validator,
Apple's tag reference, Spotify's delivery specification, Castos and Podbase found:

- episode images that are not square (Spotify requires 1:1, Apple 1400–3000 px square)
- episode descriptions over Apple's limit of 4000 bytes for `<description>`
- links without a domain in two episodes (already prevented for new texts by #217)
- a show description that is too short
- a byte-range warning from Podbase that needs an experiment on CloudFront

Old episodes are fixed by hand in the admin. **This plan adds the code that stops new episodes from
having the same problems**, then lists the manual fixes, which happen after the code is deployed.

## Agreed design

1. **Image check on upload.** `ImageUploader` rejects images that are not exactly square or whose side
   is outside 1400–3000 px. Applies to the admin and the API.
2. **"Artwork url" leaves the admin form.** The column and the values of episodes 001–019 stay (their
   covers keep working), but new covers can only be uploaded, where the check applies.
3. **Feed description size check.** Saving an episode whose rendered RSS description is over 4000 bytes
   fails with an error naming the size and the excess. Applies to the admin and the API.
4. **Manual fixes after deploy**, in this order: links, show description, CloudFront experiment,
   images, long descriptions, final validator run. They move into the description of issue #220 as a
   checklist when the code PR is opened, because this plan file is deleted once the PR is merged
   (AGENTS.md).

Not in scope: the Podcasting 2.0 namespace (separate issue later), a size display in the admin, a
check on the show description, moving the 17 old S3 covers to Cloudinary.

## What you need to know about podi

Read `AGENTS.md` in the repo root first. The parts that matter here:

- **Images** use Shrine (`app/uploaders/image_uploader.rb`, `config/initializers/shrine.rb`). In
  production the files go to Cloudinary; in tests Shrine uses in-memory storage, so no network is
  needed. Shrine validations live in an `Attacher.validate do … end` block in the uploader. They only
  run when a **new** file is assigned, so existing episodes with old images stay savable.
- **Episode covers** come from `EpisodePresenter#artwork_url` (`app/presenters/episode_presenter.rb`):
  the uploaded `image` if present, else the legacy `artwork_url` column, else the default artwork from
  the settings.
- **The RSS description** is built by `EpisodeFeedPresenter#description_with_show_notes_html`
  (`app/presenters/episode_feed_presenter.rb`): description, chapter list, show notes ("Nodes" in the
  admin) and a contact block from the settings, all as HTML. `Setting.current` raises
  `"no setting"` when there is no `Setting` record.
- **Permitted attributes**: the admin controller permits exactly `Episode::ATTRIBUTES`
  (`app/models/episode.rb`); the API has its own list in `Api::V1::EpisodesController`.
- **Unpermitted parameters raise in test** (`ActionController::UnpermittedParameters`). A spec or a
  form that still sends a removed field fails loudly.
- **Specs**: run only the files you touch, e.g. `bin/rspec spec/models/episode_spec.rb`. Never the full
  suite locally; CI runs it. Style: `bin/rubocop`. Factories are in `spec/factories/`; the `:episode`
  factory attaches a real mp3 and sets a short description ("we talk about bikes and things") and
  show notes ("* some nodes"), and has no uploaded image.
- **Commits**: conventional prefix, imperative, summary under 50 characters, no AI attribution
  trailer. Branch first; never commit to `master`.

## Tasks

Work strictly in order. Each task ends green and with a commit.

### Task 0: Branch

```sh
git checkout master && git pull --ff-only origin master
git checkout -b check-cover-and-feed-size
```

### Task 1: Read image dimensions on upload

Shrine needs an analyzer to read width and height. Its `store_dimensions` plugin uses the `fastimage`
gem by default (pure Ruby, no native libraries).

1. Add to the `Gemfile`, next to the `shrine` gems:

   ```ruby
   gem "fastimage", "~> 2.4"
   ```

   Run `bundle install`. Check that `Gemfile.lock` only gained `fastimage`.

2. Write the failing spec. Create `spec/uploaders/image_uploader_spec.rb`:

   ```ruby
   require "rails_helper"

   RSpec.describe ImageUploader do
     it "stores the dimensions of an uploaded image" do
       episode = build(:episode, image: Rack::Test::UploadedFile.new(
         Rails.root.join("spec/fixtures/001-vorstellung.jpg"), "image/jpeg"
       ))

       expect(episode.image.dimensions).to eq([ 1500, 1500 ])
     end
   end
   ```

   Run `bin/rspec spec/uploaders/image_uploader_spec.rb`: it fails with `NoMethodError` for
   `dimensions`.

3. In `app/uploaders/image_uploader.rb`, add `plugin :store_dimensions` above `Attacher.validate`.
   Run the spec again: green.

4. Commit: `feat: read cover image dimensions on upload`.

### Task 2: Test images

Create three small solid-colour PNGs with ffmpeg (installed via Homebrew). They are tiny because they
are a single colour:

```sh
ffmpeg -loglevel error -f lavfi -i color=c=gray:s=1400x1120 -frames:v 1 spec/fixtures/image-1400x1120.png
ffmpeg -loglevel error -f lavfi -i color=c=gray:s=600x600   -frames:v 1 spec/fixtures/image-600x600.png
ffmpeg -loglevel error -f lavfi -i color=c=gray:s=3200x3200 -frames:v 1 spec/fixtures/image-3200x3200.png
sips -g pixelWidth -g pixelHeight spec/fixtures/image-*.png   # confirm the sizes
ls -la spec/fixtures/image-*.png                               # each should be a few KB
```

The existing `spec/fixtures/001-vorstellung.jpg` (1500×1500) is the valid case.

Commit: `test: add cover images of invalid sizes`.

### Task 3: Reject covers that are not square or not 1400–3000 px

1. Failing specs. In `spec/models/episode_spec.rb`, after the `describe "audio validation"` block, add:

   ```ruby
   describe "image validation" do
     def upload(name, type)
       Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures", name), type)
     end

     context "with a square image of 1500 px" do
       it "is valid" do
         expect(build(:episode, image: upload("001-vorstellung.jpg", "image/jpeg"))).to be_valid
       end
     end

     context "with an image that is not square" do
       it "is invalid", :aggregate_failures do
         episode = build(:episode, image: upload("image-1400x1120.png", "image/png"))

         expect(episode).not_to be_valid
         expect(episode.errors[:image]).to eq([ "must be square (1:1), this image is 1400×1120 px" ])
       end
     end

     context "with a square image smaller than 1400 px" do
       it "is invalid" do
         episode = build(:episode, image: upload("image-600x600.png", "image/png"))

         episode.validate
         expect(episode.errors[:image]).to eq([ "must be 1400 to 3000 px wide, this image is 600×600 px" ])
       end
     end

     context "with a square image larger than 3000 px" do
       it "is invalid" do
         episode = build(:episode, image: upload("image-3200x3200.png", "image/png"))

         episode.validate
         expect(episode.errors[:image]).to eq([ "must be 1400 to 3000 px wide, this image is 3200×3200 px" ])
       end
     end
   end
   ```

   Run `bin/rspec spec/models/episode_spec.rb`: the three invalid cases fail (no errors yet).

2. Implement in `app/uploaders/image_uploader.rb`:

   ```ruby
   class ImageUploader < Shrine
     # Apple requires square covers of 1400 to 3000 px; Spotify requires 1:1.
     SIDE_RANGE = 1400..3000

     plugin :store_dimensions

     Attacher.validate do
       validate_mime_type %w[image/jpeg image/png image/webp]

       width, height = file.dimensions
       if width.nil? || height.nil?
         errors << "dimensions could not be read"
       elsif width != height
         errors << "must be square (1:1), this image is #{width}×#{height} px"
       elsif !SIDE_RANGE.cover?(width)
         errors << "must be #{SIDE_RANGE.min} to #{SIDE_RANGE.max} px wide, this image is #{width}×#{height} px"
       end
     end
   end
   ```

   Only one size error is reported at a time: a non-square image gets the square message first,
   because that is the one Spotify enforces.

3. Run `bin/rspec spec/models/episode_spec.rb spec/uploaders/image_uploader_spec.rb`: green.

4. Check the specs that upload the existing 1500 px image still pass:
   `bin/rspec spec/requests/api/v1/episodes_spec.rb spec/system/admin/episodes_spec.rb`.

5. Commit: `feat: reject covers that Apple and Spotify refuse`.

### Task 4: The API explains a rejected cover

1. In `spec/requests/api/v1/episodes_spec.rb`, next to the context `"with audio that is not an mp3"`,
   add:

   ```ruby
   context "with a cover that is not square" do
     it "names the size", :aggregate_failures do
       cover = fixture_file_upload(Rails.root.join("spec/fixtures/image-1400x1120.png"), "image/png")

       post "/api/v1/episodes", params: { episode: episode_params.merge(image: cover) }, headers: headers

       expect(response).to have_http_status(:unprocessable_content)
       expect(response.parsed_body["messages"]).to eq("image" => [ "must be square (1:1), this image is 1400×1120 px" ])
     end
   end
   ```

2. Run the file. It should pass without code changes (the API already renders validation errors per
   field). If it fails, read the error before changing anything: the response format is defined in
   `app/controllers/api/v1/base_controller.rb`.

3. Commit: `test: cover the API response for a wrong cover`.

### Task 5: Remove "Artwork url" from the admin

1. Failing spec. In `spec/system/admin/episodes_spec.rb`, test `"create a new episode"`:
   - delete the line `fill_in "Artwork url", with: "https://test.com/001-test.png"`
   - delete the commented-out line `# expect(episode.artwork_url).to eq "https://test.com/001-test.png"`
   - add, right after `expect(page).to have_text "New Episode"`:

     ```ruby
     expect(page).to have_no_field "Artwork url"
     ```

   Add a test for the rejected upload in the same `context "when logged in as admin"`:

   ```ruby
   it "rejects a cover that is not square" do
     episode = create(:episode)

     visit "/admin/episodes/#{episode.slug}/edit"
     attach_file "Image", Rails.root.join("spec/fixtures/image-1400x1120.png")
     click_on "Save"

     expect(page).to have_content "Image must be square (1:1), this image is 1400×1120 px"
   end
   ```

   Run `bin/rspec spec/system/admin/episodes_spec.rb`: the `have_no_field` expectation fails.

2. Implement:
   - `app/views/admin/episodes/_form.html.haml`: delete the line
     `= f.input :artwork_url, hint: "Path for episodes logo"`.
   - `app/models/episode.rb`: remove `artwork_url` from `ATTRIBUTES`.
   - Do **not** touch the `artwork_url` column, the factory, or `EpisodePresenter#artwork_url`: episodes
     001–019 still use the stored URLs.

3. Run `bin/rspec spec/system/admin/episodes_spec.rb spec/models/episode_spec.rb`: green.

4. Commit: `refactor: upload covers instead of linking them`.

### Task 6: One constant for Apple's 4000 bytes

`EpisodeFeedPresenter` already cuts the plain-text summary with `truncate_bytes(4000)`. The new check
needs the same number, so it gets a name.

1. In `app/presenters/episode_feed_presenter.rb`:
   - Add below `SOCIAL_LINKS`:

     ```ruby
     # Apple shows at most this many bytes of an episode description.
     MAX_DESCRIPTION_BYTES = 4000
     ```

   - Replace `truncate_bytes(4000)` with `truncate_bytes(MAX_DESCRIPTION_BYTES)`.
   - The comment above `description_with_show_notes_html` says "up to 4000 characters". That is
     wrong (Apple counts bytes): change "characters" to "bytes".

2. Run `bin/rspec spec/presenters/episode_feed_presenter_spec.rb`: still green (pure refactoring).

3. Commit: `refactor: name Apple's description byte limit`.

### Task 7: Give episode specs a Setting

The size check in Task 8 renders the contact block, which reads `Setting.current`. These spec files
create episodes without a `Setting` and would fail with `"no setting"`:

- `spec/models/episode_spec.rb`
- `spec/presenters/episode_presenter_spec.rb`
- `spec/models/episode_statistic_spec.rb`
- `spec/models/episode_current_statistic_spec.rb`
- `spec/requests/sitemaps_spec.rb`
- `spec/requests/api/v1/tags_spec.rb`
- `spec/services/podlove_webplayer_config_builder_spec.rb`
- `spec/jobs/mp3_event_job_spec.rb`
- `spec/services/episode_creator_spec.rb`

In each, add `before { create(:setting) }` as the first hook of the outermost `describe` (after any
`let`/`subject`, per the RSpec layout rules). Do not make the validator skip when no setting exists:
a missing setting is a broken system and must stay loud.

Run all nine files: green (nothing reads the setting yet). Commit:
`test: create a setting where episodes are built`.

After Task 8, run these nine files again plus `spec/system` and `spec/requests`. If another file fails
with `"no setting"`, give it a setting the same way.

### Task 8: Reject episodes whose feed description is over 4000 bytes

1. Failing specs. In `spec/models/episode_spec.rb`, add after `describe "image validation"`:

   ```ruby
   describe "feed description size" do
     context "with a short description" do
       it "is valid" do
         expect(build(:episode)).to be_valid
       end
     end

     context "with a description over Apple's limit" do
       it "names the size and the excess", :aggregate_failures do
         episode = build(:episode, description: "a" * 4000)

         expect(episode).not_to be_valid
         expect(episode.errors[:description].first)
           .to match(/\Amakes the RSS feed description \d+ bytes, \d+ more than Apple allows \(4000\)/)
       end
     end

     context "with umlauts that stay under 4000 characters but not under 4000 bytes" do
       it "counts bytes" do
         episode = build(:episode, description: "ü" * 1900)

         expect(episode).not_to be_valid
       end
     end
   end
   ```

   ("ü" is two bytes: 1900 of them are 3800 bytes before chapters, show notes and the contact block are
   added, while being far below 4000 characters.)

   In `spec/requests/api/v1/episodes_spec.rb`, next to the cover context from Task 4:

   ```ruby
   context "with a description that makes the feed too long" do
     it "names the size", :aggregate_failures do
       post "/api/v1/episodes", params: { episode: episode_params.merge(description: "a" * 4000) },
                                headers: headers

       expect(response).to have_http_status(:unprocessable_content)
       expect(response.parsed_body["messages"]["description"].first).to start_with("makes the RSS feed description")
     end
   end
   ```

   Run both files: the new examples fail.

2. Create `app/validators/feed_description_size_validator.rb`:

   ```ruby
   # Podcast apps get the episode description from the RSS feed, built from the description, chapters,
   # show notes and the contact block. Only the rendered result can be measured against Apple's limit.
   class FeedDescriptionSizeValidator < ActiveModel::Validator
     def validate(episode)
       return if episode.description.blank?

       size = EpisodeFeedPresenter.new(episode).description_with_show_notes_html.bytesize
       limit = EpisodeFeedPresenter::MAX_DESCRIPTION_BYTES
       return if size <= limit

       episode.errors.add(:description, "makes the RSS feed description #{size} bytes, #{size - limit} more " \
                                        "than Apple allows (#{limit}). Shorten the description or show notes")
     end
   end
   ```

   The `description.blank?` guard is not an escape hatch: a blank description already fails the
   presence validation, and Redcarpet cannot render `nil`.

3. In `app/models/episode.rb`, below `validates(:description, :nodes, absolute_links: true)`:

   ```ruby
   validates_with FeedDescriptionSizeValidator
   ```

4. Run `bin/rspec spec/models/episode_spec.rb spec/requests/api/v1/episodes_spec.rb`: green. Then the
   nine files from Task 7, `spec/requests`, `spec/system` (without `js: true` specs, which need
   Docker), `spec/presenters`, `spec/services`, `spec/jobs`. Fix only "no setting" failures as in Task 7;
   anything else, stop and investigate.

5. Commit: `feat: reject episodes too long for Apple's feed`.

### Task 9: Document the rules

In `AGENTS.md` (repo root), section "Other `Episode` details", add:

```markdown
- Covers are uploaded through `image` (Shrine) and must be square, 1400–3000 px (Apple, Spotify);
  `ImageUploader` rejects anything else. The `artwork_url` column only serves episodes 001–019 from
  before the uploads and is no longer editable.
- The RSS description of an episode (description, chapters, show notes and the contact block from the
  settings) may be at most 4000 bytes. `FeedDescriptionSizeValidator` checks it on save, so episode
  specs need a `Setting` record.
```

Commit: `docs: describe cover and feed size rules`.

### Task 10: Checks and PR

1. `bin/rubocop`, `bin/brakeman --no-pager`, `bin/bundler-audit`. All clean.
2. Remove this plan file only after the PR is merged (AGENTS.md), not in this PR.
3. Open the PR against `master`:
   - Title: `Check cover size and feed description length`
   - Description: `Refs #220` (not "Closes": the manual fixes remain), the story, how to review
     (uploader, validator, then specs), design choices (presenter reuse instead of a separate size
     object, no skip without a setting, artwork_url column kept).
4. Copy the section "Manual fixes after deploy" below into the description of issue #220 as a task
   list (`gh issue edit 220 --body-file …`, keeping the existing text above it).
5. Close PR #219 with a comment: "Replaced by docs/plans/2026-10-07-feed-check-fixes.md and the
   checklist in #220."

## Manual fixes after deploy (Michael, in the admin)

Start only after the PR is merged **and deployed**: the checks then verify each fix. Edit pages are
`https://www.wartenberger.de/admin/episodes/<slug>/edit`.

1. **Links** (the admin cannot save these episodes until they are fixed). Field **Nodes**:
   - 050 (`050-rueckblick-geschichten-aus-der-wartenberger-geschichte`): replace
     `(025-maria-und-mathias-obermeier-zeitzeugen)` with
     `(https://www.wartenberger.de/episodes/025-maria-und-mathias-obermeier-zeitzeugen)` and
     `(028-max-kammerer-wartenberger-zeitzeuge)` with
     `(https://www.wartenberger.de/episodes/028-max-kammerer-wartenberger-zeitzeuge)`. Upload 050's
     square cover (step 4) in the same save.
   - 032 (`032-wartenberger-online-museum`): replace `(dhm.de/lemo/)` with `(https://www.dhm.de/lemo/)`.
2. **Show description**: Admin → Settings → Description, two to four sentences about the podcast
   (Podbase flags under 50 characters; today it is 44).
3. **CloudFront experiment** (AWS console): CloudFront → distribution `d3qd1sxnjnmo7u.cloudfront.net` →
   Behaviors → edit the default behavior → Response headers policy → create a policy with the custom
   header `Accept-Ranges: bytes` (override on) → attach → save. When the deployment is done, check:

   ```sh
   curl -s -o /dev/null -D - -r 0-1 "$(curl -s -o /dev/null -w '%{redirect_url}' \
     'https://www.wartenberger.de/episodes/063-rathaus-news-herbst-2026.mp3?notracking=1')" | grep -i accept-ranges
   ```

   Then re-run Podbase. If the byte-range message is gone, keep the policy. If not, remove the policy
   again: the message is a false positive (Podbase does not follow podi's redirect).
4. **Square covers** (1400×1400 px, PNG or JPEG; add a background rather than cutting off faces),
   uploaded in **Image**: 061, 050, 031, 028, 007, 006, 004, 002. A wrong size is rejected with the
   measured size.
5. **Long descriptions**: 041, 023, 021, 033, 045. Saving shows exactly how many bytes are too many;
   shorten **Description** or **Nodes** by that much plus a little margin.
6. **Final check**: W3C (`https://validator.w3.org/feed/check.cgi?url=https%3A%2F%2Fwww.wartenberger.de%2Fepisodes.rss`),
   Podbase and Castos. Expected leftovers: W3C `itunes:title` (Apple allows it), W3C podlove namespace
   and `itunes:summary` HTML warnings, Castos byte-range message for the feed itself (generated per
   request; ranges only matter for media), and Podbase's byte-range message if step 3 showed it is a
   false positive.
7. **Production guide** (`~/Library/CloudStorage/Dropbox/podcasts/AGENTS.md`, not in the repo): add
   the two new 422 messages (cover size, feed description size) to step 6 of the guide with what the
   agent does about them (cover: ask Michael for a correct export; description: propose a cut), and
   update the false-positive list in "Feed-Prüfung" with the results of steps 3 and 6.
8. Close #220.
