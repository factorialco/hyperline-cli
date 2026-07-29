# Changelog

All notable changes to this project will be documented in this file.

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
