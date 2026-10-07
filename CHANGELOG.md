# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added

- Coupons resource (`client.coupons`: list, get, create, update, delete) for the coupon catalog;
  `Subscriptions#update_operation` documents the `add_coupon` / `remove_coupon` payloads
- `Invoices#download_link` returns a `Hyperline::DownloadLink` (`url`, `expires_at`) with the
  pre-signed URL from the API's 302 without following it; `url` is nil when the API answers with
  the file itself, in which case callers fall back to `#download`. Works for credit notes too
- `Subscriptions#get` accepts query params, e.g. `get(id, include_live_billing: true)`
- Customer portal support: `Invoices#list_v2` / `#get_v2` (cursor-paginated `CursorCollection`),
  `Customers#get_v2`, `#payment_methods`, `#delete_payment_method`, `#portal`,
  `Subscriptions#preview_timeline` / `#simulate_updates`, the `Integrations` resource
  (`#create_component_token`) and `Hyperline::Webhook.verify!` with `WebhookSignatureError`
- `Invoices#download` follows one redirect without forwarding the Authorization header and returns
  a `Hyperline::Download` (`body`, `content_type`, `filename`; `to_str` yields the bytes, so code
  that treated the old return value as a String keeps working). It now uses `/v2/invoices/{id}/download`
  and accepts `lang:` / `locale:`
- `idempotency_key:` on `Invoices#charge`
- `Collection` accepts `args:` so a nested list (payment methods) pages with its parent id
- Features resource (list, get, create, update, archive, delete), keyed by the feature's `code`
  rather than an opaque id
- `Products#features`, `#link_feature`, `#unlink_feature` and `#archive`
- `ConflictError` (409) and `UnprocessableEntityError` (422); both previously arrived as the
  generic `ApiError`, indistinguishable from an unrecognised status
- `idempotency_key:` on every mutating method. Hyperline honours the standard `Idempotency-Key`
  header — the same key with the same body replays the first response, while the same body with
  no key applies twice — so a write is retried (429 and 5xx, bounded) only when a caller supplies
  one. `X-Idempotency-Key` is ignored by the API.

### Fixed

- Both issues listed as known under 0.2.1 below. `Subscriptions#list` used `/v1/subscriptions`,
  which answers 404 `Route not found`, so the method could never return; listing now goes through
  the v2 path. `base_path` deliberately stays on v1, because the action sub-paths genuinely live
  there. And `Collection#next_page` re-issued the resource's default `#list` whatever method had
  produced the page, so a page from a custom list method paged into the wrong endpoint.
- `Subscriptions#update_operation`'s documented payload omitted the required `payment_schedule`,
  so the example in the comment and in the spec returned 400. The verified shape and its enum
  values are now recorded on the method.

### Notes

- A feature must be archived before it can be deleted: `DELETE` on an active one answers 400
  `Cannot delete a feature that is not archived`.
- Archiving is a `PUT` for both products and features; `POST` answers 404 `Route not found`.
- `GET /v1/products/{id}/features` answers with a bare array, with no `meta`/`data` envelope.

### Known issues

- The write retry budget is a hardcoded constant while `Configuration#max_retries` governs the
  read retry, so there are two budgets and only one is reachable. Retry policy is not yet
  configurable per condition, which is why consumers that need a hard timeout or retries on 404
  still wrap `#request` themselves.

## [0.2.1] - 2026-07-29

### Fixed

- `#find_by_custom_property` and `#find_by_integration_entity_id` now page through the full
  result set. Because Hyperline silently drops unknown query params and returns the unfiltered
  list, a real match could sit beyond the first page and the finder returned `nil` — which is
  indistinguishable from "not found".
- Added the missing `require 'json'` in `BaseResource`; error-body parsing relied on `json`
  being loaded transitively by Faraday.
- Corrected `source_code_uri` and `changelog_uri` gemspec metadata, which pointed at a
  non-existent `hyperline/hyperline-ruby` repository.

### Changed

- Gemspec description now lists all eight resources instead of three.
- Added CI (RSpec + RuboCop) and expanded `.gitignore` to cover build artifacts.

### Known issues

- `Subscriptions#list` uses the v1 path while `#get`/`#update` and search use v2. Not yet fixed;
  affects subscription listing only.
- `Collection#next_page` always re-issues the resource's default `#list`, so pagination on
  custom list methods such as `Subscriptions#list_templates` returns the wrong resource after
  the first page.

## [0.2.0] - 2026-07-29

### Added

- Plans resource (list, get, create, update, delete, archive, unarchive)
- Price Configurations resource (list, get, create, update, delete, update_prices, archive, unarchive)
- Price Books resource (list, get, create, update, delete, add_products, remove_product)
- Aggregators resource (list, get, create, update, delete)
- Custom Properties resource (list, create, update, delete)
- `#find_by_custom_property` and `#find_by_integration_entity_id` on all resources, with
  client-side re-verification of server-side filters
- `Subscriptions#update_operation` for seat changes and scheduled operations
- Subscriptions `#get`/`#update` moved to the v2 API

### Fixed

- Restored `DEFAULT_BASE_URL` to `https://api.hyperline.co`; a sandbox host had been committed
  by mistake

## [0.1.0] - 2026-03-24

### Added

- Initial release
- `Hyperline::Client` with bearer token authentication
- Products resource (list, get, create, update, archive)
- Subscriptions resource (list, get, create, update, cancel, pause, activate, reactivate, reinstate, renew, templates)
- Invoices resource (list, get, create, update, delete, validate, charge, void, download, credit notes, transactions)
- Automatic pagination via `Collection#each_page` and `Collection#auto_paginate`
- Error hierarchy: `ApiError`, `AuthenticationError`, `BadRequestError`, `NotFoundError`, `RateLimitError`, `ServerError`
- Retry middleware with exponential backoff on 429/5xx
- Global configuration via `Hyperline.configure`
