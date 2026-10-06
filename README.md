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
