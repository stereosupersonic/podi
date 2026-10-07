# Podi API v1

The Podi API lets a script or an AI agent create **draft** podcast episodes. A draft is never public on
its own: it stays off the homepage, the episode list, search and the RSS feed until a human approves it
in the admin. This is expected behaviour, not an error.

Base URL: `https://www.wartenberger.de/api/v1`

All responses are JSON.

## Authentication

An admin creates a token under **Admin → API Tokens**. It is shown once. Send it with every request:

```
Authorization: Bearer podi_…
```

A token only works while its owner is an admin. A revoked token stops working immediately.

Check a token:

```sh
curl -s https://www.wartenberger.de/api/v1/ping -H "Authorization: Bearer $PODI_TOKEN"
```

`200 OK`:

```json
{ "status": "ok", "user": { "email": "admin@example.com" }, "token": { "name": "n8n publishing" } }
```

## Create a draft episode

`POST /episodes` as `multipart/form-data`. All fields are nested under `episode[...]`.

| Field | Required | Format |
|---|---|---|
| `episode[audio]` | yes | MP3 file (`audio/mpeg`). Other formats are rejected |
| `episode[title]` | yes | Text, unique across all episodes |
| `episode[description]` | yes | Markdown. Links must be full URLs (`https://…` or `mailto:…`). Together with the chapters, the show notes and the contact block, the description may take at most 4000 bytes in the RSS feed (Apple's limit); the error names the size and the excess |
| `episode[nodes]` | yes | Show notes, Markdown. Links must be full URLs (`https://…` or `mailto:…`); they count toward the 4000-byte feed limit above |
| `episode[published_on]` | yes | Date, `YYYY-MM-DD` |
| `episode[chapter_marks]` | no | One chapter per line: `HH:MM:SS.mmm Title`, e.g. `00:00:41.018 Intro` |
| `episode[transcript]` | no | WebVTT content (starts with `WEBVTT`) |
| `episode[tag_list]` | no | Comma-separated, e.g. `Interview, Geschichte`. Reuse tags from `GET /tags` |
| `episode[image]` | no | Cover image file: JPEG, PNG or WebP |

Any other field (for example `active`, `visible`, `number`, `slug`) is ignored. The episode number is
always the next free number, and the slug is built from the zero-padded number and the title.

```sh
curl -s https://www.wartenberger.de/api/v1/episodes \
  -H "Authorization: Bearer $PODI_TOKEN" \
  -F "episode[title]=Folge über den Markt" \
  -F "episode[description]=Wir reden über den Markt." \
  -F "episode[nodes]=* Link 1" \
  -F "episode[published_on]=2026-10-20" \
  -F "episode[tag_list]=Interview, Markt" \
  -F "episode[audio]=@folge.mp3;type=audio/mpeg"
```

`201 Created`, with a `Location` header pointing to the preview page:

```json
{ "episode": { "id": 87, "number": 42, "slug": "042-folge-ueber-den-markt",
  "title": "Folge über den Markt", "published_on": "2026-10-20",
  "active": false, "visible": true, "tags": ["Interview", "Markt"], "duration": null,
  "preview_url": "https://www.wartenberger.de/episodes/042-folge-ueber-den-markt" } }
```

- `active: false` means waiting for human approval. Share `preview_url` with the person who approves it.
- `duration` is `null` at first; it is filled in once the audio has been analysed.

## List tags

`GET /tags` returns every tag used by any episode, drafts included, sorted alphabetically. Reuse these
tags when you set `episode[tag_list]` instead of inventing variants of the same topic ("Musik",
"Musiker", "Band").

```sh
curl -s https://www.wartenberger.de/api/v1/tags -H "Authorization: Bearer $PODI_TOKEN"
```

`200 OK`:

```json
{ "tags": ["Geschichte", "Interview", "Musik"] }
```

## Errors

Every 4xx error has the same shape: `error` (a machine-readable code), and `message` and/or `messages`.

| Status | `error` | Meaning | What to do |
|---|---|---|---|
| 400 | `bad_request` | Fields not nested under `episode[...]` | Fix the request shape |
| 401 | `unauthorized` | Token missing, wrong or revoked | Ask an admin for a valid token; don't retry |
| 422 | `validation_failed` | A field is invalid, or `audio`/`image` was sent as text instead of a file; `messages` lists them per field | Fix the listed fields and send again |
| 429 | `rate_limited` | More than 60 requests a minute with your token, or 10 failed authentications a minute from your IP | Wait one minute |
| 500 | — | Unexpected server error; the body is not JSON in this shape | Retry once later; if it persists, tell an admin |

After 10 failed authentications from your IP, every request from it gets `429` for the rest of the
minute, even with a valid token.

`400`:

```json
{ "error": "bad_request", "message": "Missing parameter: episode" }
```

`401`:

```json
{ "error": "unauthorized", "message": "Missing or invalid API token" }
```

`422`:

```json
{ "error": "validation_failed",
  "message": "Title has already been taken and Audio must be an MP3 file (audio/mpeg)",
  "messages": { "title": ["has already been taken"], "audio": ["must be an MP3 file (audio/mpeg)"] } }
```

`429`:

```json
{ "error": "rate_limited", "message": "Too many requests, retry in a minute" }
```

## Compatibility

v1 may gain new fields in responses and new optional request fields. Don't treat unknown response fields
as errors. Breaking changes get a new version path (`/api/v2`).
