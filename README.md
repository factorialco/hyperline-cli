# Hyperline Ruby Client

Ruby client for the [Hyperline](https://hyperline.co) billing API.

## Installation

Add to your Gemfile:

```ruby
gem "hyperline"
```

Then run `bundle install`, or install directly:

```bash
gem install hyperline
```

## Configuration

### Per-client

```ruby
client = Hyperline::Client.new(api_key: "prod_xxx")
```

### Global

```ruby
Hyperline.configure do |config|
  config.api_key      = ENV["HYPERLINE_API_KEY"]
  config.base_url     = "https://sandbox.api.hyperline.co"  # default: https://api.hyperline.co
  config.timeout      = 30   # seconds (default)
  config.open_timeout = 10   # seconds (default)
  config.max_retries  = 3    # retries on 429/5xx (default)
end

client = Hyperline.client  # uses global config
```

## Usage

### Products

```ruby
# List
products = client.products.list(take: 10)
products.data     # => [{ "id" => "itm_abc", ... }, ...]
products.total    # => 42

# Get
product = client.products.get("itm_abc")

# Create
product = client.products.create(name: "Pro Plan", type: "flat_fee")

# Update
product = client.products.update("itm_abc", name: "Enterprise Plan")

# Archive
client.products.delete("itm_abc")
```

### Subscriptions

```ruby
# List
subs = client.subscriptions.list(status: "active")

# Get (uses v2 API)
sub = client.subscriptions.get("sub_abc")

# Create
sub = client.subscriptions.create(customer_id: "cus_xxx", plan_id: "plan_xxx")

# Update (uses v2 API)
client.subscriptions.update("sub_abc", name: "Updated")

# Actions
client.subscriptions.cancel("sub_abc", cancel_at: "period_end")
client.subscriptions.pause("sub_abc")
client.subscriptions.activate("sub_abc")
client.subscriptions.reactivate("sub_abc")
client.subscriptions.reinstate("sub_abc")
client.subscriptions.renew("sub_abc")

# Templates
templates = client.subscriptions.list_templates
template  = client.subscriptions.get_template("tpl_abc")
```

### Invoices

```ruby
# List
invoices = client.invoices.list(status: "to_pay")

# Get
invoice = client.invoices.get("inv_abc")

# Create
invoice = client.invoices.create(customer_id: "cus_xxx")

# Update (PATCH, for draft/grace invoices)
client.invoices.update("inv_abc", memo: "Updated memo")

# Delete (draft only)
client.invoices.delete("inv_abc")

# Actions
client.invoices.validate("inv_abc")     # draft → to_pay
client.invoices.charge("inv_abc", payment_method_id: "pm_xxx", idempotency_key: "key")
client.invoices.void("inv_abc")         # void invoice

# Download PDF
# Download (follows one redirect; returns Hyperline::Download with body, content_type, filename)
pdf = client.invoices.download("inv_abc", lang: "en", locale: "en-GB")

# Temporary pre-signed URL, not followed (url is nil if the API returned the file itself; use download then)
link = client.invoices.download_link("inv_abc")
link.url
link.expires_at
File.binwrite(pdf.filename || "invoice.pdf", pdf.body)

# Credit notes
client.invoices.create_credit_note("inv_abc", reason: "Duplicate charge")

# Mark uncollectible
client.invoices.mark_uncollectible("inv_abc")

# Transactions
client.invoices.create_transaction("inv_abc", amount: 5000)
client.invoices.delete_transaction("inv_abc", "tx_xxx")
```

### v2 invoices (cursor pagination)

```ruby
page = client.invoices.list_v2(customer_id: "cus_xxx", limit: 50)
page.next_cursor
page.next_page                     # nil on the last page
client.invoices.list_v2(customer_id: "cus_xxx").auto_paginate { |invoice| process(invoice) }
client.invoices.get_v2("inv_abc")
```

### Customer portal

```ruby
client.customers.get_v2("cus_xxx")
client.customers.payment_methods("cus_xxx", take: 20)   # Collection
client.customers.delete_payment_method("cus_xxx", "pm_xxx", idempotency_key: "key")
client.customers.portal("cus_xxx")                      # => { "url" => ... }
client.subscriptions.preview_timeline("sub_xxx", max_events: 10)
client.subscriptions.simulate_updates("sub_xxx", type: "update_count", payload: { ... })
client.integrations.create_component_token(customer_id: "cus_xxx")
```

### Webhooks

```ruby
event = Hyperline::Webhook.verify!(
  payload: request.raw_post,   # the raw body, not a re-serialised one
  headers: request.headers,
  secret: ENV.fetch("HYPERLINE_WEBHOOK_SECRET"),
  tolerance: 300
)
# raises Hyperline::WebhookSignatureError when the signature or timestamp is invalid
```

### Pagination

```ruby
# Manual pagination
page = client.invoices.list(take: 50)
while page.next_page?
  page = page.next_page
end

# Iterate pages
client.invoices.list(take: 50).each_page do |page|
  page.data.each { |invoice| process(invoice) }
end

# Auto-paginate all items
client.invoices.list(take: 100).auto_paginate do |invoice|
  process(invoice)
end
```

### Error Handling

```ruby
begin
  client.products.get("itm_missing")
rescue Hyperline::AuthenticationError => e
  # 401 — invalid API key
rescue Hyperline::NotFoundError => e
  # 404 — resource not found
rescue Hyperline::RateLimitError => e
  # 429 — rate limit exceeded (retries exhausted)
rescue Hyperline::BadRequestError => e
  # 400 — invalid request
rescue Hyperline::ServerError => e
  # 5xx — server error (retries exhausted)
rescue Hyperline::ApiError => e
  # catch-all for other API errors
  e.status   # HTTP status code
  e.message  # error message from API
  e.body     # parsed response body
end
```

## Development

```bash
bundle install
bundle exec rspec       # run tests
bundle exec rubocop     # lint
gem build hyperline.gemspec  # build gem
```

## License

MIT License. See [LICENSE.txt](LICENSE.txt).
