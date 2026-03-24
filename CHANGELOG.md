# Changelog

All notable changes to this project will be documented in this file.

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
