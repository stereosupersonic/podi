# Migration Plan: Solid Queue → Sidekiq

## Goal

Replace Solid Queue with Sidekiq for background job processing. Add Redis as a
Kamal accessory. Run Sidekiq as a separate container via Kamal's job server role.
Remove all Solid Queue tables, config, and the queue database. Keep Solid Cache
(it's independent and stays on the primary database).

## Why

- Sidekiq is battle-tested, faster (Redis vs PostgreSQL polling), and has a rich
  web UI built in
- Consistent with the exhiby project (same server, same patterns)
- Removes the need for a separate queue database and 11 Solid Queue tables
- Mission Control Jobs UI is replaced by Sidekiq's built-in web dashboard

## Current State

| Component | Current | Target |
|-----------|---------|--------|
| Job backend | Solid Queue (PostgreSQL) | Sidekiq (Redis) |
| Queue database | Separate `podi_*_queue` DB | Removed |
| Redis | Not used | New Kamal accessory |
| Job process | Inside Puma (`SOLID_QUEUE_IN_PUMA=true`) | Separate Kamal container |
| Job UI | Mission Control Jobs (`/jobs`) | Sidekiq Web (`/sidekiq`) |
| Recurring jobs | `config/recurring.yml` | Not needed (was only cleaning Solid Queue tables) |

## What stays unchanged

- **Solid Cache** — keeps running on the primary database. No changes to `solid_cache`
  gem, `solid_cache.yml`, `cache_schema.rb`, or the cache migration.
- **Job classes** — `Mp3EventJob` and `GeoDataJob` use ActiveJob and work with any backend.
  No changes needed to job code.
- **Job specs** — use `:test` adapter, not affected by backend changes.
- **ApplicationJob** — `retry_on Timeout::Error` works identically with Sidekiq.

## Existing Jobs

Two jobs, both in `app/jobs/`:

**`Mp3EventJob`** — processes MP3 download events, increments counters, parses device
info, enqueues `GeoDataJob`. No explicit queue assignment (uses `default`).

**`GeoDataJob`** — fetches geolocation data for IP addresses. Assigned to `default`
queue. Retries `StandardError` 5 times with polynomial backoff.

Both jobs use `ActiveJob::Base` via `ApplicationJob`, so they work with any backend
without code changes.

## Existing Job Specs

**`spec/jobs/mp3_event_job_spec.rb`** — tests enqueueing and execution with
`have_enqueued_job` and `perform_enqueued_jobs`. Uses `:test` adapter.

**`spec/jobs/geo_data_job_spec.rb`** — same pattern. Both pass without changes.

---

## Task 1: Add Sidekiq gem, create initializer and config

**What**: Add the Sidekiq gem, configure Redis connection, and create the Sidekiq
queue configuration file.

### Files to create/change

**Gemfile** — replace `solid_queue` and `mission_control-jobs` with `sidekiq`:
```ruby
# Remove these three lines:
gem "solid_queue"
gem "mission_control-jobs"

# Add:
gem "sidekiq", "~> 7.3"
```

Keep `solid_cache` — it's independent.

**Create `config/sidekiq.yml`**:
```yaml
:concurrency: <%= ENV.fetch("SIDEKIQ_CONCURRENCY", 5) %>

:queues:
  - [default, 2]
  - [low, 1]
```

Two queues are enough for this app. `default` (weight 2) handles both jobs.
`low` exists for future use. No `critical` queue needed — this app has no
user-facing jobs that need priority.

**Create `config/initializers/sidekiq.rb`**:
```ruby
redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end
```

**Delete `config/initializers/solid_queue.rb`** (currently sets Mission Control base controller).

### Commands

```bash
bundle install
```

### How to test

```bash
bundle exec rspec spec/jobs/
```

Jobs use `:test` adapter — they don't touch Sidekiq or Redis. Should pass unchanged.

### Commit

```
git commit -m "feat: add Sidekiq gem with Redis configuration

Replace solid_queue and mission_control-jobs gems with sidekiq.
Add config/sidekiq.yml and config/initializers/sidekiq.rb."
```

---

## Task 2: Update environment configs and remove Solid Queue Puma plugin

**What**: Switch the ActiveJob adapter from `:solid_queue` to `:sidekiq` in
production and development. Remove the Puma plugin that ran Solid Queue
inside the web process.

### Files to change

**`config/environments/production.rb`** — line 47:
```ruby
# Change from:
config.active_job.queue_adapter = :solid_queue

# To:
config.active_job.queue_adapter = :sidekiq
```

Also remove the commented-out `solid_queue.connects_to` lines (48-50).

**`config/environments/development.rb`** — line 18:
```ruby
# Change from:
config.active_job.queue_adapter = :solid_queue

# To (matching exhiby's pattern):
config.active_job.queue_adapter = ENV.fetch("SIDEKIQ_ENABLED", false) ? :sidekiq : :async
```

Also remove the commented-out `solid_queue.connects_to` / `solid_cache.connects_to`
lines (19-20).

**`config/environments/test.rb`** — no change needed. Already uses `:test`.

**`config/puma.rb`** — remove the Solid Queue plugin line:
```ruby
# Delete this line (currently line 38):
plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"] == "true"
```

**`config/application.rb`** — remove Mission Control config (line 38):
```ruby
# Delete this line:
config.mission_control.jobs.http_basic_auth_enabled = false
```

### How to test

```bash
bundle exec rspec
```

Full suite should pass. The test environment uses `:test` adapter, unaffected.

### Commit

```
git commit -m "refactor: switch ActiveJob adapter from solid_queue to sidekiq

Update production and development environments. Remove Solid Queue
Puma plugin — Sidekiq runs as a separate process."
```

---

## Task 3: Update routes — replace Mission Control with Sidekiq Web UI

**What**: Remove the Mission Control Jobs engine mount and add Sidekiq's built-in
web dashboard.

### Files to change

**`config/routes.rb`** — line 2:
```ruby
# Remove:
mount MissionControl::Jobs::Engine, at: "/jobs"

# Add:
require "sidekiq/web"
mount Sidekiq::Web => "/sidekiq"
```

**Security**: Sidekiq::Web needs authentication. The current Mission Control setup
used `Admin::BaseController`. For Sidekiq, add a constraint in routes:

```ruby
# config/routes.rb (at the top, before draw block)
require "sidekiq/web"

Rails.application.routes.draw do
  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => "/sidekiq"
  end

  # ... rest of routes
end
```

Wait — this app doesn't use Devise (`authenticate` block). It uses custom auth.
Instead, protect via a Rack middleware constraint or the existing admin pattern.

Simpler approach — mount under the admin namespace with a before_action check
already handled by `Admin::BaseController`. But Sidekiq::Web is a Rack app, not
a Rails controller. The simplest secure approach:

```ruby
require "sidekiq/web"

Rails.application.routes.draw do
  # Sidekiq Web UI — protected by HTTP basic auth in production
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    ActiveSupport::SecurityUtils.secure_compare(username, ENV.fetch("SIDEKIQ_WEB_USER", "admin")) &
      ActiveSupport::SecurityUtils.secure_compare(password, ENV.fetch("SIDEKIQ_WEB_PASSWORD", "password"))
  end
  mount Sidekiq::Web => "/sidekiq"

  # ... rest of routes
end
```

Add `SIDEKIQ_WEB_USER` and `SIDEKIQ_WEB_PASSWORD` to Kamal secrets in Task 5.

**Update system specs** — the jobs spec references the `/jobs` path:

Check `spec/system/admin/jobs_spec.rb`:
```bash
cat spec/system/admin/jobs_spec.rb
```
This spec is currently skipped (`xit`). Update the path from `/jobs` to `/sidekiq`
if you un-skip it later.

**Update layout** — the application layout links to `/jobs` for admins:

`app/views/layouts/application.html.haml` line 74:
```haml
# Change from:
  = link_to "Jobs", "/jobs", class: "nav-link text-white"

# To:
  = link_to "Jobs", "/sidekiq", class: "nav-link text-white"
```

### How to test

```bash
bundle exec rspec
```

Also verify the route exists:
```bash
bin/rails routes | grep sidekiq
```

### Commit

```
git commit -m "refactor: replace Mission Control Jobs with Sidekiq Web UI

Mount Sidekiq::Web at /sidekiq with HTTP basic auth protection.
Remove Mission Control Jobs engine mount."
```

---

## Task 4: Remove Solid Queue database, tables, and config files

**What**: Create a migration to drop all Solid Queue tables from the primary
database. Remove the queue database config and schema files. Remove Solid Queue
config files.

### Important context

The Solid Queue tables were originally created via `db/migrate/20260210113546_add_solid_queue.rb`.
They live in the **primary database** (the `connects_to` for the queue DB was
always commented out in production.rb). So we drop them from the primary DB.

### Files to create

**Create migration** — `bin/rails generate migration RemoveSolidQueueTables`:

```ruby
class RemoveSolidQueueTables < ActiveRecord::Migration[8.1]
  def up
    drop_table :solid_queue_blocked_executions, if_exists: true
    drop_table :solid_queue_claimed_executions, if_exists: true
    drop_table :solid_queue_failed_executions, if_exists: true
    drop_table :solid_queue_ready_executions, if_exists: true
    drop_table :solid_queue_recurring_executions, if_exists: true
    drop_table :solid_queue_recurring_tasks, if_exists: true
    drop_table :solid_queue_scheduled_executions, if_exists: true
    drop_table :solid_queue_semaphores, if_exists: true
    drop_table :solid_queue_pauses, if_exists: true
    drop_table :solid_queue_processes, if_exists: true
    drop_table :solid_queue_jobs, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      "Solid Queue tables cannot be recreated. Re-run the original migration if needed."
  end
end
```

Note: `solid_queue_jobs` must be dropped last because other tables have foreign keys
referencing it. The `if_exists: true` guards against partial migrations.

### Files to delete

```bash
rm config/queue.yml               # Solid Queue dispatcher/worker config
rm config/recurring.yml           # Solid Queue recurring tasks
rm db/queue_schema.rb             # Queue database schema (never used — was for separate DB)
```

### Files to change

**`config/database.yml`** — remove the `queue:` sections from all environments.

Current `database.yml` has `primary:`, `queue:`, and `cache:` for each environment.
Remove all `queue:` blocks:

```yaml
development:
  primary: &primary_development
    <<: *default
    database: podi_development
  cache:
    <<: *primary_development
    database: <%= ENV.fetch('DATABASE_NAME_CACHE', "podi_development_cache") %>
    migrations_paths: db/cache_migrate

test:
  primary: &primary_test
    <<: *default
    database: podi_test
  cache:
    <<: *primary_test
    database: <%= ENV.fetch('DATABASE_NAME_CACHE', "podi_test_cache") %>
    migrations_paths: db/cache_migrate

production:
  primary: &primary_production
    <<: *default
    adapter: postgresql
    encoding: unicode
    pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
    url: <%= ENV['DATABASE_URL'] %>
  cache:
    <<: *primary_production
    migrations_paths: db/cache_migrate
```

### Commands

```bash
bin/rails db:migrate
bin/rails db:test:prepare
```

### How to test

```bash
# Verify migration ran:
bin/rails db:migrate:status | grep solid_queue

# Verify tables are gone:
bin/rails runner "puts ActiveRecord::Base.connection.tables.select { |t| t.start_with?('solid_queue') }"
# Should output nothing

# Run full suite:
bundle exec rspec
```

### Commit

```
git commit -m "refactor: remove Solid Queue tables and queue database config

Drop all 11 solid_queue_* tables. Remove queue database sections from
database.yml. Delete queue.yml, recurring.yml, and queue_schema.rb."
```

---

## Task 5: Update Kamal deploy config — add Redis, add job server role

**What**: Add a Redis accessory and a Sidekiq job server role to `config/deploy.yml`.
Remove the `SOLID_QUEUE_IN_PUMA` env var.

### Reference

Look at exhiby's `config/deploy.yml` for the exact pattern. Podi deploys to a
**different server** (37.120.190.122) than exhiby (37.120.188.157), so there's
no port conflict for Redis.

### Files to change

**`config/deploy.yml`** — multiple changes:

**Add job server role** (after the `web:` section):
```yaml
servers:
  web:
    - 37.120.190.122
  job:
    hosts:
      - 37.120.190.122
    cmd: bundle exec sidekiq -C config/sidekiq.yml
    options:
      memory: 512m
```

**Update env section** — remove `SOLID_QUEUE_IN_PUMA`, add `REDIS_URL`:
```yaml
env:
  clear:
    DATABASE_HOST: podi-postgres
    DEFAULT_URL_HOST: www.wartenberger.de
    REDIS_URL: redis://podi-redis:6379/0
    RAILS_LOG_LEVEL: info
    # Remove: SOLID_QUEUE_IN_PUMA: true
    # Remove: # JOB_CONCURRENCY: 3
```

Note the Redis hostname: `podi-redis`. Kamal names accessories as
`<service>-<accessory>`, so the Redis accessory named `redis` under the `podi`
service gets the Docker network hostname `podi-redis`.

**Add Redis accessory** (in the `accessories:` section):
```yaml
  redis:
    image: redis:7-alpine
    host: 37.120.190.122
    port: 127.0.0.1:6379:6379
    cmd: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
    directories:
      - redis_data:/data
```

**Add Sidekiq web auth secrets** (if using HTTP basic auth from Task 3):
```yaml
env:
  secret:
    - RAILS_MASTER_KEY
    # ... existing secrets ...
    - SIDEKIQ_WEB_USER
    - SIDEKIQ_WEB_PASSWORD
```

**Update `.kamal/secrets`** — add the new secrets:
```bash
SIDEKIQ_WEB_USER=admin
SIDEKIQ_WEB_PASSWORD=<generate-a-strong-password>
```

**Update `.env`** — add Redis URL for local development:
```bash
REDIS_URL=redis://localhost:6379/0
SIDEKIQ_ENABLED=true
```

**Update `Procfile.dev`** — add Sidekiq worker:
```
web: bin/server
css: sass ./app/assets/stylesheets/application.scss:./app/assets/builds/application.css --no-source-map --load-path=node_modules --watch
jobs: bundle exec sidekiq -C config/sidekiq.yml
```

Note: The `jobs:` line replaces the old `jobs: bin/jobs` which ran Solid Queue.

### How to test

**Locally** (requires Redis running — `brew install redis && brew services start redis`):

```bash
# Start Sidekiq:
bundle exec sidekiq -C config/sidekiq.yml

# In another terminal, enqueue a test job:
bin/rails runner "GeoDataJob.perform_later(1, '8.8.8.8')"

# Watch Sidekiq output — it should pick up and process the job
# (will fail with RecordNotFound since event ID 1 doesn't exist, but
# that proves Sidekiq is connected to Redis and processing)
```

**On deploy**:

```bash
# Boot the Redis accessory first:
bin/kamal accessory boot redis

# Deploy (will start both web and job containers):
bin/kamal deploy

# Verify Sidekiq is running:
bin/kamal app logs -r job

# Verify Redis is reachable:
bin/kamal accessory exec redis "redis-cli ping"
# Should return: PONG
```

### Commit

```
git commit -m "feat: add Redis accessory and Sidekiq job server to Kamal

Add Redis 7 Alpine container with 256MB LRU cache and persistence.
Add dedicated Sidekiq job server role (512MB memory limit).
Remove SOLID_QUEUE_IN_PUMA — jobs no longer run inside Puma."
```

---

## Task 6: Remove solid_queue gem and leftover files

**What**: Final cleanup — remove the `solid_queue` gem from the Gemfile (it was
kept until now for the migration to run). Remove any remaining references.

### Wait — why not remove it in Task 1?

The migration in Task 4 (`RemoveSolidQueueTables`) uses `drop_table` which is
plain ActiveRecord — it doesn't need the `solid_queue` gem. So actually, you CAN
remove it in Task 1 and it will work fine. The gem only provides the models
(`SolidQueue::Job`, etc.) and the supervisor — neither is needed for dropping tables.

If you already removed it in Task 1, skip this task.

If you kept it around, remove now:

### Files to change

**Gemfile** — verify these lines are gone:
```ruby
# Should already be removed in Task 1:
gem "solid_queue"
gem "mission_control-jobs"
```

### Files to verify are deleted

```bash
# All of these should be gone:
ls config/queue.yml             # deleted in Task 4
ls config/recurring.yml         # deleted in Task 4
ls db/queue_schema.rb           # deleted in Task 4
ls config/initializers/solid_queue.rb  # deleted in Task 1
```

### Search for stale references

```bash
grep -r "solid_queue\|SolidQueue\|mission_control\|MissionControl" \
  app/ config/ spec/ --include="*.rb" --include="*.yml" --include="*.haml"
```

This should return zero results. If anything is found, remove it.

Also check:
```bash
grep -r "SOLID_QUEUE" config/ .env*
```

Remove any remaining `SOLID_QUEUE_IN_PUMA` or `JOB_CONCURRENCY` references.

### How to test

```bash
bin/ci
```

Full CI pipeline must pass.

### Commit

```
git commit -m "chore: remove remaining Solid Queue references

Final cleanup of Solid Queue to Sidekiq migration."
```

---

## Task 7: Verify Docker build

**What**: The Dockerfile doesn't need changes — Sidekiq runs from the same Docker
image as the web server (just a different CMD). But verify the build works.

### How to test

```bash
# Build:
docker build -t podi-test .

# Verify Sidekiq can start:
docker run --rm podi-test bundle exec sidekiq --help

# Verify the config file is in the image:
docker run --rm podi-test cat /rails/config/sidekiq.yml
```

### Commit

No commit needed if nothing changed. If the Dockerfile needed tweaks, commit them.

---

## Summary

| Task | Risk | Effort | Key test |
|------|------|--------|----------|
| 1. Add Sidekiq gem + config | Low | 15 min | `rspec spec/jobs/` passes |
| 2. Switch adapter, remove Puma plugin | Low | 10 min | Full suite passes |
| 3. Update routes (Sidekiq Web UI) | Low | 15 min | `/sidekiq` accessible |
| 4. Drop Solid Queue tables + DB config | Medium | 20 min | Tables gone, suite passes |
| 5. Kamal: Redis + job server role | Medium | 30 min | `kamal deploy`, jobs process |
| 6. Final cleanup | Low | 10 min | `bin/ci` passes |
| 7. Docker verification | Low | 5 min | `docker build` succeeds |

Total: ~7 commits, ~15 files changed.

## Deployment Order

On the production server, deploy in this order:

```bash
# 1. Boot Redis first (before deploying app):
bin/kamal accessory boot redis

# 2. Deploy app (starts web + job containers):
bin/kamal deploy

# 3. Verify Sidekiq is processing:
bin/kamal app logs -r job

# 4. Verify web UI:
# Visit https://wartenberger.de/sidekiq (with HTTP basic auth)

# 5. Drop the unused queue databases (if they were ever created):
bin/kamal app exec "bin/rails runner 'puts :ok'"
# If the podi_production_queue DB exists on the server, drop it manually:
# bin/kamal accessory exec postgres "psql -U postgres -c 'DROP DATABASE IF EXISTS podi_production_queue'"
```

## Rollback

Each task is a separate commit. If Sidekiq doesn't work in production:

```bash
# Revert the deploy.yml changes to get SOLID_QUEUE_IN_PUMA back:
git revert HEAD~N  # where N is number of commits to revert

# Redeploy:
bin/kamal deploy

# Stop Redis if no longer needed:
bin/kamal accessory stop redis
```

The Solid Queue tables migration is irreversible — if you need to go back,
re-run the original `AddSolidQueue` migration:
```bash
bin/rails db:migrate VERSION=20260210113546
```
