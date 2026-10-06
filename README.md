[![codecov](https://codecov.io/gh/stereosupersonic/podi/branch/master/graph/badge.svg?token=BW3VA5GCLZ)](https://codecov.io/gh/stereosupersonic/podi)

===========
# Podi

podcast hosting

## setup sidemap

configure s3 access

S3_ACCESS_KEY
S3_SECRET_KEY
S3_BUCKET_NAME
S3_REGION

scheduler call
```
rake sitemap:refresh
```

## API

Admins create API tokens under Admin → API Tokens. The token-authenticated API creates draft episodes
that stay unlisted until approved in the admin. See [docs/api.md](docs/api.md).

### Checking a deployment

1. Admin → API Tokens: create a token named "smoke test" and copy it.
2. `curl -s https://www.wartenberger.de/api/v1/ping -H "Authorization: Bearer $TOKEN"` answers `200`.
3. Create an episode with the `curl` example from `docs/api.md` and a short mp3: `201`.
4. The homepage, `/episodes` and `/episodes.rss` don't show it, its `preview_url` plays it, and the admin
   episode list marks it "Draft".
5. Eleven requests with a wrong token: the eleventh answers `429`. If it never does, kamal-proxy is not
   passing the client IP and every caller shares one failed-login counter.
6. Delete the test episode in the Rails console (`bin/kamal console`) and revoke the token.
