# Episode YouTube link as player fallback

Rough plan, not yet agreed in detail. Open questions are at the end.

## Goal

Episodes are also published on YouTube (as a premiere, after the release on the website). Store that
link per episode and offer it on the episode page when the web player cannot play the episode, so
listeners always have a way to hear it.

## Today

`app/views/shared/_webplayer.html.haml` renders the Podlove web player
(`/vendor/podlove-web-player.js`) and already has one fallback: if `podlovePlayer` is not defined after
5 seconds (50 × 100 ms), it shows a native `<audio>` element instead. Gaps:

- The `<audio>` fallback plays the same mp3. When the problem is the audio itself (CDN, S3, the redirect
  in `episodes#show`), it fails as well.
- `podlovePlayer(...).then(...)` has no `.catch`. A player that loads but fails to initialize leaves an
  invisible container (`opacity: 0`) and no fallback.
- Playback errors after initialization are not noticed at all.

## Plan

### 1. Store the link

- Migration: `episodes.youtube_url` (string, nullable).
- `Episode`: `validates :youtube_url, url: true` (existing `UrlValidator`), optionally restricted to
  `youtube.com` / `youtu.be` hosts. Add to `Episode::ATTRIBUTES`.
- Admin form: `= f.input :youtube_url` with a hint.
- API: accept `youtube_url` on `POST /api/v1/episodes` and return it in the JSON. In practice the
  YouTube premiere is uploaded after the draft is created, and the API cannot update episodes, so the
  link is usually entered in the admin. See open questions.

### 2. Show the fallback

- `EpisodePresenter#youtube_url` (or `nil`), passed to the `shared/webplayer` partial.
- The partial renders a hidden fallback block when a link exists: "Probleme mit dem Player? Die Folge
  gibt es auch auf YouTube" with a link (`target: _blank`, `rel: noopener`).
- Reveal it from the existing script in three cases:
  1. `podlovePlayer` not available after 5 seconds (today's `<audio>` branch; show both).
  2. `podlovePlayer(...)` rejects: add `.catch`, show the `<audio>` element and the YouTube block.
  3. The native `<audio>` fallback fires an `error` event.
- Without a stored link everything behaves as today.

### 3. Specs

- Model: valid and invalid `youtube_url`.
- Admin system spec: the field is saved.
- Request spec: the episode page contains the hidden fallback block with the link when set, and none
  when not.
- One `js: true` system spec for the reveal (runs in Docker with `bin/docker-tests`, see AGENTS.md):
  block the player script, expect the YouTube link to become visible.

## Recommendation

A **link, not an embedded YouTube player**. An embed loads YouTube (and its cookies) on the page, which
needs a mention in the privacy page and arguably a consent click; a link loads nothing until the
listener clicks. If an embed is wanted later, use `youtube-nocookie.com` and load it only on click.

## Open questions

- **Always visible or only on failure?** Showing the link permanently below the player (small, "Auch
  auf YouTube") needs no detection at all and also helps listeners who simply prefer YouTube. Showing it
  only on failure keeps the page cleaner but depends on detecting every failure, and Podlove does not
  report all playback errors to the page.
- **Backfill:** existing episodes have no link, and not every older episode may be on YouTube. Enter
  them by hand in the admin, or a one-off script matching the channel's videos to episodes (needs a
  YouTube Data API key)?
- **API:** add an update endpoint (`PATCH /api/v1/episodes/:id`, `youtube_url` only) so the production
  agent can store the link after the premiere, or keep it a manual admin step?
- **Feed:** add the YouTube link to the show notes in the RSS feed as well? Apple and Spotify allow
  links; it would also give podcast-app listeners a video option.
