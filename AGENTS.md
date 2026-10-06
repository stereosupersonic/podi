# AGENTS.md

Guidance for coding agents (Claude Code, Codex, Cursor, …) working in this repository.

## What Podi Is

Podi is a self-hosted podcast publishing platform for **one podcast with one admin**, live at
https://www.wartenberger.de. It covers:

- Public episode pages, an episode list with endless scrolling, and live search
- The RSS feed for podcast directories (`/episodes.rss`)
- mp3 download tracking with device detection and geolocation
- An admin area (`/admin`) for episodes, settings, download events and statistics

## Tech Stack

| Layer | Technology |
|---|---|
| Language / framework | Ruby 3.4 (`.ruby-version`), Rails 8.1 |
| Database | PostgreSQL 17, with native arrays, JSONB and Scenic views |
| Jobs | Sidekiq 7 + Redis (`config/sidekiq.yml`, queues `default` and `low`) |
| Cache | Redis |
| Frontend | HAML, Hotwire (Turbo + Stimulus), importmap, Propshaft, dartsass, Bootstrap 5.3, SimpleForm |
| Audio storage | Active Storage (disk locally, S3 + CloudFront in production) |
| Image storage | Shrine + Cloudinary (`app/uploaders/image_uploader.rb`) |
| Auth | Session-based, `has_secure_password` on `User` (no Devise) |
| Rate limiting | Rack::Attack (`config/initializers/rack_attack.rb`) |
| Monitoring | Rollbar (errors), Scout APM (performance) |
| Deployment | Docker + Kamal to a single VPS |

## Getting It Running

Requirements: Ruby from `.ruby-version`, PostgreSQL and Redis running locally.

```sh
bin/setup      # installs gems, prepares the database, then starts bin/dev
bin/dev        # foreman with Procfile.dev: web server, dartsass watcher, Sidekiq
```

`config/database.yml` connects to `DATABASE_HOST` (default `0.0.0.0`) as
`DATABASE_USERNAME`/`DATABASE_PASSWORD` (default `postgres`/`postgresdb`). Local configuration goes in
`.env`, loaded by dotenv.

## Running Specs and Checks

**Run only the specs relevant to your change locally.** The full suite runs in CI.

```sh
bin/rspec spec/models/episode_spec.rb          # one file
bin/rspec spec/requests/episodes_spec.rb:12    # one example
bin/rubocop                                     # style (rubocop-rails-omakase + project rules)
bin/brakeman --no-pager                         # security static analysis
bin/bundler-audit                               # vulnerable gems
```

`bin/ci` runs everything (setup, RuboCop, RSpec, bundler-audit, Brakeman) as defined in `config/ci.rb`.
`bin/docker-tests` runs the full suite in Docker exactly as GitHub Actions does
(`docker-compose.test.yml`, with Selenium in a `chrome` container).

### Spec Layout

| Directory | What goes there |
|---|---|
| `spec/models/` | Validations, scopes, model methods |
| `spec/requests/` | Controller behaviour over HTTP: status codes, formats, redirects |
| `spec/system/` | Capybara flows. Default driver is `rack_test`; tag with `js: true` only when JavaScript is needed (Selenium, much slower) |
| `spec/system/admin/` | Admin flows. Log in with `login_as(create(:user, :admin))` from `spec/support/login_helpers.rb` |
| `spec/services/`, `spec/presenters/`, `spec/jobs/` | Unit specs for those layers |

- Factories are in `spec/factories/`. The `:episode` factory attaches `spec/fixtures/test-001.mp3` and
  analyzes it, so episodes have a real duration.
- Many episode pages need a `Setting` record: `create(:setting)`.
- Stub the GeoIP lookup in specs that trigger downloads:
  `allow(FetchGeoData).to receive(:call).and_return({})`.
- Custom matchers live in `spec/support/` (`html_matcher`, `xml_matcher`, `meta_matcher`, …).

## Architecture and Conventions

### Where Code Goes

- **Controllers** (`app/controllers/`) stay thin. Admin controllers inherit from `Admin::BaseController`,
  which runs `authorize_admin`. Shared helpers (`current_user`, `current_setting`, `authenticate_user!`)
  live in `ApplicationController`.
- **Service objects** (`app/services/`) inherit from `BaseService`, which includes `ActiveModel::Model`
  and offers `ServiceName.call(args)` → `new(args).call`. Name them for the action they perform
  (`ConvertChapters`, `FetchGeoData`, `ParseVtt`).
- **Presenters** (`app/presenters/`) inherit from `ApplicationPresenter` (a `SimpleDelegator`). Use `o`
  for the wrapped object and `h` for view helpers, and wrap collections with `EpisodePresenter.wrap(records)`.
  View formatting belongs here, never in models or controller helpers.
- **Jobs** (`app/jobs/`) run on Sidekiq through Active Job.
- **Statistics** come from PostgreSQL views managed by Scenic (`db/views/`), read through the read-only
  models `EpisodeStatistic` and `EpisodeCurrentStatistic`. All time windows (`a12h`, `a1d`, `a7d`, …)
  are computed in the view SQL, so a new window means a new view version. Change a view with a new
  versioned SQL file and `update_view`, never by editing an existing version.
- **Uploads use two stacks:** episode images go through Shrine + Cloudinary (`image_data` column,
  `ImageUploader`), audio through Active Storage + S3. Follow the stack of the file type you are touching.
- `WelcomeController#epsiode` (sic) serves the numeric shortcut route `/:id` (e.g. `/006`). The
  misspelling is part of the routing; don't rename it in passing.

### Episode Visibility

The publication state of an `Episode` is defined by these columns:

| Field | Meaning |
|---|---|
| `active` | Released: listed on the homepage, in the episode list, search, the RSS feed and the sitemap |
| `visible` | Reachable by direct link (`/episodes/:slug`, `/:number`). `visible: true, active: false` is how previews are shared |
| `published_on` | Release date; episodes dated in the future are not listed yet |
| `rss_feed` | Default `true`. Only filters the RSS feed, on top of `active`: `rss_feed: false` keeps a released episode on the website but out of podcast apps (Spotify, Apple). No effect on unreleased episodes |

`Episode.published` (`visible AND active AND published_on <= today`) is the public listing.
`episodes#show` only requires `visible`.

Other `Episode` details:

- `slug` is built in `Admin::EpisodesController#build_slug` from the zero-padded number and the title
  (`"001 Title".parameterize(locale: :de)`). `number`, `slug` and `title` are unique.
- Permitted attributes are listed in `Episode::ATTRIBUTES`; the admin controller permits exactly those.
- Audio is required (`has_one_attached :audio`). Duration and size come from the blob metadata
  (`config/initializers/active_storage_analyzers.rb`).
- `tags` is a PostgreSQL text array, edited as a comma-separated `tag_list`.

### Download Tracking

`EpisodesController#show` with format `mp3` deduplicates per IP for 2 minutes through `Rails.cache`. It
then publishes the `track_mp3_downloads` notification and redirects to the CDN URL.
`config/initializers/register_events.rb` subscribes and enqueues `Mp3EventJob`, which parses the user
agent, creates an `Event` and enqueues `GeoDataJob`. Logged-in users and `?notracking=1` are not
tracked.

### Settings

`Setting.current` is the singleton podcast configuration (title, author, iTunes category, social URLs,
default artwork). It raises if no record exists.

## Code Style

- **HAML** for all templates, never ERB.
- **Double quotes** for strings (enforced by RuboCop).
- Strong params use `params.require(:model).permit(...)`, matching the existing controllers.
- Admin forms use SimpleForm (`= f.input :field`).
- I18n keys use the full path (`t("episodes.search.placeholder")`), never lazy lookup. Locales are in
  `config/locales/` (`de`, `en`).
- Read configuration from `ENV` in `config/` and initializers. New environment variables go into the
  README and, if they are needed in production, into `config/deploy.yml`.
- Match the style of the surrounding code, and keep comments to the *why*.

## Workflow

- **Branch first.** Never commit to `master`; create a feature branch before touching any file.
- **TDD.** Write a failing spec, see it fail, write the minimal code to pass it, then refactor.
- **Commits** are atomic, use conventional prefixes and the imperative mood: `feat: add episode tags`,
  `fix: …`, `refactor: …`, `test: …`, `docs: …`. Keep the summary under 50 characters.
- **Pull requests** target `master` on GitHub (`stereosupersonic/podi`). CI (`.github/workflows/ci.yml`)
  runs Brakeman, bundler-audit, RuboCop and the full RSpec suite in Docker.
- **Implementation plans** live in `docs/plans/`.

## Deployment

A merge to `master` triggers `.github/workflows/deploy.yml` once CI has passed. It deploys with Kamal
(`config/deploy.yml`) to the production VPS: a `web` role behind kamal-proxy with SSL, a `job` role
running `bin/jobs`, and Postgres and Redis as accessories. Secrets come from `.kamal/secrets`.

Useful Kamal aliases: `bin/kamal console`, `bin/kamal logs`, `bin/kamal shell`, `bin/kamal dbc`.
