# OmniAuth LINE Login

OmniAuth strategy for [LINE Login](https://developers.line.biz/en/docs/line-login/overview/) with OpenID Connect email support.

This is a fork of [omniauth-line](https://github.com/kazasiki/omniauth-line) by kazasiki, enhanced with ID Token verification to extract `email` and `email_verified` claims via LINE's `/oauth2/v2.1/verify` API.

## Installation

Add to your Gemfile:

```ruby
gem 'omniauth-line-login'
```

Then `bundle install`.

## Usage

```ruby
# config/initializers/omniauth.rb or devise.rb
config.omniauth :line, ENV['LINE_CHANNEL_ID'], ENV['LINE_CHANNEL_SECRET'],
  scope: 'profile openid email'
```

**Important**: The `email` scope is required to receive an ID Token containing email claims. You must also apply for the "Email address" permission in your LINE Developers Console channel settings.

## What's Different from omniauth-line

The original `omniauth-line` gem only calls LINE's `/v2/profile` API, which does not return email. This fork adds:

- **ID Token verification** via LINE's `/oauth2/v2.1/verify` API (server-side verification)
- **`info[:email]`** — extracted from the verified ID Token claims
- **`info[:email_verified]`** — the `email_verified` claim from the ID Token
- **`extra[:id_token_claims]`** — full ID Token claims for debugging and extension

## Auth Hash

```ruby
{
  uid: 'U02fa1e93...',
  info: {
    name: 'Display Name',
    image: 'https://profile.line-scdn.net/...',
    description: 'Status message',
    email: 'user@example.com',        # NEW
    email_verified: true               # NEW
  },
  extra: {
    raw_info: { ... },                 # LINE /v2/profile response
    id_token_claims: { ... }           # NEW: verified ID Token claims
  }
}
```

## Error Handling

If the ID Token is not present (e.g., `openid` scope not included) or the verify API returns an error, `email` and `email_verified` will be `nil` and the application can fall back to its own email collection flow. Errors are logged via `OmniAuth.logger`.

## Nonce Verification

This gem does **not** perform nonce verification. If your application requires nonce validation, you can access the nonce from `extra[:id_token_claims]['nonce']` and verify it in your callback controller.

## License

MIT License. See [LICENSE](LICENSE) for details.

Original work by [kazasiki](https://github.com/kazasiki/omniauth-line).

Repository: [buferago/omniauth-line](https://github.com/buferago/omniauth-line)
