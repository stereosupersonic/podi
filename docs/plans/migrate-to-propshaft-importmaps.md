# Migration Plan: Propshaft + Importmaps + Bootstrap 5

## Goal

Replace the current asset pipeline (sprockets + esbuild + jQuery + Bootstrap 4) with the
modern Rails 8.1 stack (propshaft + importmaps + Bootstrap 5, no jQuery).

## Why

- `sprockets-rails` tries to compile `.scss` files at runtime, causing `cannot load sassc` errors
- jQuery and Bootstrap 4 are end-of-life — Bootstrap 5 dropped the jQuery dependency
- `importmap-rails` eliminates the need for Node.js to bundle JavaScript
- `propshaft` is the Rails 8.1 default — simpler, no compilation, just serves files

## Current State

| Component | Current | Target |
|-----------|---------|--------|
| Asset pipeline | sprockets-rails | propshaft |
| JS bundling | esbuild (jsbundling-rails) | importmap-rails |
| CSS bundling | sass + postcss (cssbundling-rails) | cssbundling-rails (keep) |
| CSS framework | Bootstrap 4.6.2 | Bootstrap 5.3 |
| jQuery | yes (global `$`) | removed |
| Node.js required | yes (esbuild + sass + postcss) | yes (sass + postcss only) |

## Architecture Decisions

- **Keep cssbundling-rails** for CSS — the SCSS files use Bootstrap mixins (`@include media-breakpoint-up`) and
  variables (`$black`, `$primary`), which require a Sass compiler. Propshaft doesn't compile anything.
- **Drop jsbundling-rails** — the JS is minimal (12 lines). Importmaps handle this without a bundler.
- **No Stimulus controllers yet** — the only JS interaction is Bootstrap tooltips. We'll initialize them
  with a tiny inline script, not a full Stimulus setup. YAGNI.

## Prerequisites

- All existing system specs pass (`bundle exec rspec spec/system/`)
- Working local dev environment (`bin/dev` or `rails s`)
- Git branch created from current HEAD: `git checkout -b migrate-propshaft-importmaps`

---

## Task 1: Replace sprockets-rails with propshaft

**What**: Swap the asset serving library. Propshaft serves files from `app/assets/` without
trying to compile them. It uses digest-stamped filenames for cache-busting, just like sprockets.

**Why first**: This is the lowest-risk change. Both libraries serve the same asset helpers
(`stylesheet_link_tag`, `javascript_include_tag`, `image_path`). The CSS and JS build pipelines
(cssbundling, jsbundling) are unchanged.

### Files to change

**Gemfile** — line 16:
```ruby
# Remove:
gem "sprockets-rails"

# Add:
gem "propshaft"
```

**Delete** `app/assets/config/manifest.js`:
```
# This file told sprockets which files to precompile.
# Propshaft doesn't use it — it serves everything in app/assets/ automatically.
rm app/assets/config/manifest.js
```

### Commands

```bash
bundle install
# Verify assets still compile:
bin/rails assets:precompile
# Clean up:
bin/rails assets:clobber
```

### How to test

1. Run `bin/dev` (or `rails s` + `yarn build` + `yarn build:css`)
2. Visit `http://localhost:3000` — page should look identical
3. Open browser DevTools → Network tab:
   - `application.css` loads with a digest hash in the URL
   - `application.js` loads with a digest hash in the URL
   - Images load (favicon, about page photos)
   - Font Awesome icons render in the footer
4. Run system specs:
   ```bash
   bundle exec rspec spec/system/welcome_spec.rb
   bundle exec rspec spec/system/episodes_spec.rb
   ```

### What can go wrong

- **Missing assets**: Propshaft serves everything under `app/assets/`. If any file was outside
  that tree, it won't be found. Check browser console for 404s.
- **`asset_path` returning wrong paths**: Propshaft uses `.manifest.json` (generated during
  `assets:precompile`) to map logical paths to digested paths. In development, it serves
  files directly without digests.

### Commit

```
git add -p
git commit -m "refactor: replace sprockets-rails with propshaft

Propshaft is the Rails 8.1 default asset pipeline. It serves pre-built
assets without attempting runtime compilation, which fixes the sassc
load error in Docker test builds."
```

---

## Task 2: Upgrade Bootstrap 4 → Bootstrap 5 (CSS only)

**What**: Update the Bootstrap npm package and fix all CSS class name changes in views
and SCSS files. JavaScript changes come in Task 3.

**Why**: Bootstrap 5 dropped the jQuery dependency. We can't remove jQuery (Task 3) or
switch to importmaps (Task 4) until Bootstrap 5 is in place.

**Reference**: https://getbootstrap.com/docs/5.3/migration/

### Breaking class changes in this codebase

These are ALL the Bootstrap 4 → 5 class renames found in the views:

| File | Line | Bootstrap 4 | Bootstrap 5 |
|------|------|-------------|-------------|
| `app/views/layouts/application.html.haml` | 61 | `.ml-auto` | `.ms-auto` |
| `app/views/layouts/application.html.haml` | 119, 125, 130, 135, 140, 145, 149 | `.pl-0.pr-3` | `.ps-0.pe-3` |
| `app/views/layouts/application.html.haml` | 50 | `"data-dismiss" => "alert"` | `"data-bs-dismiss" => "alert"` |
| `app/views/layouts/application.html.haml` | 57 | `"data-target"`, `"data-toggle"` | `"data-bs-target"`, `"data-bs-toggle"` |
| `app/views/admin/episodes/index.html.haml` | 40 | `.badge-pill`, `.badge-#{class}` | `.rounded-pill`, `.text-bg-#{class}` |
| `app/views/admin/episodes/index.html.haml` | 40 | `"data-toggle" => "tooltip"` | `"data-bs-toggle" => "tooltip"` |
| `app/views/shared/_episode_show.html.haml` | 5 | `.font-weight-light` | `.fw-light` |
| `app/views/shared/_episode.html.haml` | 6 | `.font-weight-light` | `.fw-light` |
| `app/views/shared/_episode.html.haml` | 15 | `.font-weight-bold` | `.fw-bold` |
| `app/views/shared/_episode_inline.html.haml` | 5, 8 | `.font-weight-light` | `.fw-light` |
| `app/views/episodes/index.html.haml` | 10 | `.font-weight-light` | `.fw-light` |
| `app/views/welcome/index.html.haml` | 25 | `.font-weight-bold` | `.fw-bold` |
| `app/views/welcome/about.html.haml` | 23 | `.font-weight-bold` | `.fw-bold` |
| `app/views/welcome/about.html.haml` | 30, 54 | `.font-weight-light` | `.fw-light` |
| `app/views/users/sessions/new.html.haml` | 10, 14, 18 | `.form-group` | `.mb-3` |

### Summary of class renames

```
ml-*  →  ms-*     (margin-left → margin-start)
mr-*  →  me-*     (margin-right → margin-end)
pl-*  →  ps-*     (padding-left → padding-start)
pr-*  →  pe-*     (padding-right → padding-end)

font-weight-light  →  fw-light
font-weight-bold   →  fw-bold
font-weight-normal →  fw-normal

badge-pill    →  rounded-pill
badge-{color} →  text-bg-{color}

form-group    →  mb-3  (Bootstrap 5 removed .form-group entirely)

data-toggle   →  data-bs-toggle
data-dismiss  →  data-bs-dismiss
data-target   →  data-bs-target
data-placement → data-bs-placement

close         →  btn-close  (the dismiss button class)
```

### Files to change

**package.json** — update dependencies:
```json
{
  "dependencies": {
    "bootstrap": "^5.3.0",
    // REMOVE popper.js — Bootstrap 5 bundles @popperjs/core internally
    // REMOVE "popper.js": "^1.16.1"
  }
}
```

**app/assets/stylesheets/application.scss** — update import (no change needed,
`@import "bootstrap/scss/bootstrap"` works in both v4 and v5). But check for
removed variables/mixins. Key change: `$font-size-base + .1rem` syntax still works.

**All 24 HAML view files listed above** — apply the class renames from the table.

### Testing the close button change (layout)

The alert dismiss button changes from:
```haml
# Bootstrap 4:
%a.close{"data-dismiss" => "alert"} ×

# Bootstrap 5:
%button.btn-close{"data-bs-dismiss" => "alert", type: "button", "aria-label" => "Close"}
```
Note: Bootstrap 5 uses `<button>` with a built-in SVG icon, not a text `×`.

### Commands

```bash
yarn install
yarn build:css
# Check for Sass compilation errors — Bootstrap 5 removed some variables/mixins.
# If errors occur, check https://getbootstrap.com/docs/5.3/migration/#sass
```

### How to test

1. Build CSS: `yarn build:css` — must compile without errors
2. Run `bin/dev`, visit every page:
   - Homepage (`/`) — layout, footer spacing, social icons
   - Episodes list (`/episodes`) — heading styles
   - Episode show page (create one via admin if needed)
   - About page (`/about`) — team member photos, headings
   - Admin episodes (`/admin/episodes`) — badges, tooltips (tooltips won't work yet — that's Task 3)
   - Login page (`/login`) — form layout
3. Check: no visual regressions. Spacing, colors, and fonts should look the same.
4. Run ALL system specs:
   ```bash
   bundle exec rspec spec/system/
   ```
   All specs should pass. They test content and links, not CSS classes, so they
   should be unaffected. Exception: if any spec checks for `.close` or `.badge-pill`
   elements by CSS selector — search first:
   ```bash
   grep -r "badge-pill\|\.close\|data-dismiss\|data-toggle\|font-weight" spec/
   ```

### Commit

```
git add -p
git commit -m "refactor: upgrade Bootstrap 4 to Bootstrap 5

Update all views for Bootstrap 5 class renames (ml→ms, pl→ps,
font-weight→fw, badge-pill→rounded-pill, data-toggle→data-bs-toggle).
Replace popper.js with Bootstrap 5's bundled Popper."
```

---

## Task 3: Remove jQuery

**What**: Delete jQuery and replace the only jQuery usage (tooltip initialization) with
vanilla JavaScript using Bootstrap 5's native API.

**Why**: jQuery is 87KB minified. The app uses it for exactly one thing: initializing
Bootstrap tooltips on `turbo:load`. Bootstrap 5 provides a native JS API for this.

### Current jQuery usage (entire codebase)

There are exactly 2 files:

**`app/javascript/src/jquery.js`** (the entire file):
```javascript
import jquery from "jquery"
window.jQuery = jquery
window.$ = jquery
```

**`app/javascript/application.js`** lines 9-11:
```javascript
$(document).on("turbo:load", function () {
  $("[data-toggle='tooltip']").tooltip();
});
```

After the Bootstrap 5 migration (Task 2), the tooltip selector is `[data-bs-toggle='tooltip']`.

### Files to change

**Delete** `app/javascript/src/jquery.js`

**`app/javascript/application.js`** — rewrite entirely:
```javascript
import "@hotwired/turbo-rails"
import * as bootstrap from "bootstrap"

document.addEventListener("turbo:load", () => {
  document.querySelectorAll("[data-bs-toggle='tooltip']").forEach((el) => {
    new bootstrap.Tooltip(el)
  })
})
```

**`package.json`** — remove jQuery:
```json
{
  "dependencies": {
    // REMOVE: "jquery": "^3.5.1"
  }
}
```

### Commands

```bash
yarn install
yarn build
```

### How to test

1. Run `bin/dev`
2. Visit the admin episodes page (`/admin/episodes`) — hover over badges.
   Tooltips should appear. This is the only place tooltips are used.
3. Visit homepage — navbar collapse button should work (click hamburger on mobile viewport)
4. Trigger a flash message (e.g., log in) — the dismiss `×` button should close the alert
5. Open browser console — no errors (especially no `$ is not defined` or `jQuery is not defined`)
6. Run system specs:
   ```bash
   bundle exec rspec spec/system/
   ```

### What can go wrong

- **`$ is not defined`**: Search the entire codebase for jQuery references you missed:
  ```bash
  grep -r '\$(' app/ --include="*.js" --include="*.haml" --include="*.erb"
  grep -r 'jQuery' app/ --include="*.js" --include="*.haml" --include="*.erb"
  ```
  There should be zero results.

### Commit

```
git add -p
git commit -m "refactor: remove jQuery dependency

Replace jQuery tooltip initialization with Bootstrap 5 native JS API.
jQuery was used for exactly one DOM query — not worth 87KB."
```

---

## Task 4: Replace jsbundling-rails with importmap-rails

**What**: Stop using esbuild to bundle JavaScript. Instead, use importmaps — the browser
loads ES modules directly from URLs, no bundling step needed.

**How importmaps work**: Instead of bundling all JS into one file, a `<script type="importmap">`
tag in the HTML tells the browser where to find each module. When your code says
`import "@hotwired/turbo-rails"`, the browser looks up the URL from the importmap and
fetches it directly. No build step.

**Reference**: https://github.com/rails/importmap-rails

### Files to change

**Gemfile**:
```ruby
# Remove:
gem "jsbundling-rails", "~> 0.2.1"

# Add:
gem "importmap-rails"
```

**Create `config/importmap.rb`**:
```ruby
# Pin npm packages by running: bin/importmap pin <package>
pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
```

Note: We do NOT pin Bootstrap JS here. Bootstrap's JS is large and uses Popper.js
internally, which doesn't work well with importmaps (dynamic `require()` calls).
Instead, we'll load Bootstrap JS via the CSS build or a CDN script tag.
See "Bootstrap JS with importmaps" section below.

**`app/javascript/application.js`** — simplify:
```javascript
import "@hotwired/turbo-rails"

document.addEventListener("turbo:load", () => {
  document.querySelectorAll("[data-bs-toggle='tooltip']").forEach((el) => {
    new bootstrap.Tooltip(el)
  })
})
```

**`app/views/layouts/application.html.haml`** — line 39:
```haml
# Remove:
= javascript_include_tag "application", defer: true

# Add:
= javascript_importmap_tags
```

### Bootstrap JS with importmaps

Bootstrap's JavaScript doesn't work as an ES module import via importmaps because it
has internal CommonJS-style code. Two options:

**Option A (recommended — CDN script tag)**:
Add to `app/views/layouts/application.html.haml`, after `stylesheet_link_tag`:
```haml
= stylesheet_link_tag "application", media: "all"
%script{src: "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js", defer: true, integrity: "sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz", crossorigin: "anonymous"}
= javascript_importmap_tags
```

**Option B (vendored — no CDN dependency)**:
```bash
# Download Bootstrap JS bundle to vendor directory
curl -o vendor/javascript/bootstrap.bundle.min.js \
  https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js
```
Then in `config/importmap.rb`:
```ruby
pin "bootstrap", to: "bootstrap.bundle.min.js", preload: true
```
And in `application.js`:
```javascript
import "bootstrap"
```

Option B is better for production (no external dependency). Choose one.

### Files to delete

- `app/assets/builds/application.js` (was generated by esbuild — importmaps don't produce this)

### package.json — remove JS build dependencies

```json
{
  "dependencies": {
    // REMOVE: "@hotwired/stimulus": "^3.2.2"
    // REMOVE: "@hotwired/turbo-rails": "8.0.0-beta.1"
    // REMOVE: "esbuild": "^0.27.3"
    // REMOVE: "nodemon": "^3.0.1"
    // KEEP: "autoprefixer", "bootstrap", "postcss", "postcss-cli", "sass"
    // KEEP: "@fortawesome/fontawesome-free" (used by SCSS)
  },
  "scripts": {
    // REMOVE: "build": "esbuild ..."
    // REMOVE: "watch:css" — cssbundling-rails handles this via Procfile
    // KEEP: "build:css:compile", "build:css:prefix", "build:css"
  }
}
```

Final `package.json` should look like:
```json
{
  "name": "podi",
  "private": true,
  "dependencies": {
    "@fortawesome/fontawesome-free": "^6.4.2",
    "autoprefixer": "^10.4.16",
    "bootstrap": "^5.3.0",
    "postcss": "^8.4.31",
    "postcss-cli": "^11.0.1",
    "sass": "^1.69.5"
  },
  "scripts": {
    "build:css:compile": "sass ./app/assets/stylesheets/application.scss:./app/assets/builds/application.css --no-source-map --load-path=node_modules",
    "build:css:prefix": "postcss ./app/assets/builds/application.css --use=autoprefixer --output=./app/assets/builds/application.css",
    "build:css": "yarn build:css:compile && yarn build:css:prefix"
  }
}
```

**Procfile.dev** — update:
```
web: bin/rails server -p 3000
css: yarn build:css --watch
jobs: bin/jobs
```
Remove the `js:` line — there's no JS build step anymore.

### Commands

```bash
bundle install
yarn install
bin/rails importmap:install  # generates config/importmap.rb if you didn't create it manually
yarn build:css               # rebuild CSS only
```

### How to test

1. Run `bin/dev`
2. View page source — you should see a `<script type="importmap">` block in the `<head>`
   containing the module URLs
3. Open browser DevTools → Network tab:
   - `application.js` should NOT appear as a single bundled file
   - Instead you'll see individual module fetches (turbo, stimulus, etc.)
4. Test every interactive element:
   - Navbar hamburger menu (mobile viewport) — must toggle
   - Flash alert dismiss button — must close
   - Admin tooltips — must appear on hover
   - Turbo navigation — clicking links should NOT full-page reload (check Network tab)
5. Run ALL specs:
   ```bash
   bundle exec rspec
   ```

### What can go wrong

- **`Uncaught TypeError: Failed to resolve module specifier`**: An import in `application.js`
  is not pinned in `config/importmap.rb`. Pin it or remove the import.
- **Bootstrap JS not loading**: If using Option A (CDN), check the `<script>` tag loads.
  If using Option B (vendored), check the file exists in `vendor/javascript/`.
- **Turbo not working**: Pages full-reload instead of Turbo-navigating. Check that
  `javascript_importmap_tags` is in the layout and `@hotwired/turbo-rails` is pinned.

### Commit

```
git add -p
git commit -m "refactor: replace jsbundling-rails with importmap-rails

Remove esbuild and Node.js JS bundling. Use browser-native ES module
imports via importmaps. Node.js is still needed for Sass/PostCSS."
```

---

## Task 5: Clean up Dockerfile and build config

**What**: The Dockerfile installs Node.js and Yarn for CSS compilation. With jsbundling gone,
verify the build still works. Node is still needed (for sass + postcss), but we can
remove the esbuild-related steps.

### Files to check

**Dockerfile** — the `yarn install` step should still work. It now only installs
sass, postcss, autoprefixer, bootstrap, and fontawesome (CSS dependencies).
No changes needed unless `yarn build` was referenced (it was removed from package.json).

Verify the asset precompile step works:
```dockerfile
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile
```
This calls `yarn build:css` (via cssbundling-rails) and then propshaft to digest the output.

**Dockerfile.test** — same verification.

**.dockerignore** — no changes needed.

**config/deploy.yml** — no changes needed (asset_path is already `/rails/public/assets`).

### Commands

```bash
# Test the Docker build locally:
docker build -t podi-test .
# Verify assets are in the image:
docker run --rm podi-test ls /rails/public/assets/
```

### Commit

```
git add -p
git commit -m "chore: verify Docker build with propshaft and importmaps

No Dockerfile changes needed — Node.js is still required for Sass/PostCSS
CSS compilation. JS bundling is no longer needed."
```

---

## Task 6: Final verification and cleanup

**What**: Full regression test. Remove any leftover files.

### Cleanup checklist

- [ ] `app/assets/config/` directory — delete if empty (manifest.js was removed in Task 1)
- [ ] `app/assets/builds/application.js` — delete (no longer generated by esbuild)
- [ ] `app/javascript/src/` directory — delete (jquery.js was removed in Task 3)
- [ ] `node_modules/` — run `yarn install` to prune removed packages
- [ ] `yarn.lock` — should be updated from `yarn install`
- [ ] `Gemfile.lock` — should be updated from `bundle install`
- [ ] Search for any remaining references to removed gems:
  ```bash
  grep -r "sprockets\|jsbundling\|esbuild\|jquery" app/ config/ spec/ --include="*.rb" --include="*.haml" --include="*.js" --include="*.yml"
  ```

### Full test suite

```bash
# Lint
bundle exec rubocop

# Security
bundle exec brakeman --no-pager

# All specs
bundle exec rspec

# System specs specifically (these exercise the full frontend)
bundle exec rspec spec/system/

# Manual smoke test — visit every page:
# /              (homepage)
# /episodes      (episode list)
# /episodes/:slug (episode detail)
# /about         (about page)
# /imprint       (legal)
# /privacy       (legal)
# /login         (session form)
# /admin/episodes (admin — after logging in)
# /admin/statistics
# /admin/events
# /admin/settings
# /jobs          (mission control)
```

### Commit

```
git add -p
git commit -m "chore: remove leftover files from asset pipeline migration

Delete esbuild output, jQuery source, and empty directories."
```

---

## Summary

| Task | Risk | Effort | Key test |
|------|------|--------|----------|
| 1. sprockets → propshaft | Low | 15 min | Assets load, system specs pass |
| 2. Bootstrap 4 → 5 (CSS) | Medium | 1-2 hrs | Visual check all pages, system specs pass |
| 3. Remove jQuery | Low | 15 min | No console errors, tooltips work |
| 4. jsbundling → importmaps | Medium | 30 min | Turbo navigation works, all JS loads |
| 5. Dockerfile verification | Low | 15 min | `docker build` succeeds |
| 6. Cleanup | Low | 15 min | Full test suite green |

Total estimated files changed: ~15 files across 6 commits.

## Rollback

Each task is a separate commit. If anything breaks:
```bash
git revert HEAD    # undo last commit
# or
git reset --soft HEAD~1  # undo commit, keep changes staged
```

If the whole migration needs to be abandoned:
```bash
git checkout master -- Gemfile Gemfile.lock package.json yarn.lock \
  app/assets/ app/javascript/ app/views/ config/ Procfile.dev
bundle install && yarn install
```
