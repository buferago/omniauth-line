# OmniAuth LINE Login

[LINE Login](https://developers.line.biz/ja/docs/line-login/overview/) 用の OmniAuth ストラテジーです。OpenID Connect の ID トークンからメールアドレスを取得できます。

[kazasiki/omniauth-line](https://github.com/kazasiki/omniauth-line) のフォーク版で、LINE の `/oauth2/v2.1/verify` API による ID トークン検証機能を追加しています。

## インストール

Gemfile に追加してください：

```ruby
gem 'omniauth-line-login'
```

その後 `bundle install` を実行します。

## 使い方

```ruby
# config/initializers/omniauth.rb または devise.rb
config.omniauth :line, ENV['LINE_CHANNEL_ID'], ENV['LINE_CHANNEL_SECRET'],
  scope: 'profile openid email'
```

**重要**: メールアドレスを含む ID トークンを取得するには `email` スコープが必要です。LINE Developers Console のチャネル設定で「メールアドレス取得権限」を申請してください。

## omniauth-line との違い

オリジナルの `omniauth-line` は LINE の `/v2/profile` API のみを呼び出すため、メールアドレスを返しません。本フォークでは以下を追加しています：

- **ID トークン検証** — LINE の `/oauth2/v2.1/verify` API によるサーバーサイド検証
- **`info[:email]`** — 検証済み ID トークンのクレームから取得したメールアドレス
- **`info[:email_verified]`** — ID トークンの `email_verified` クレーム
- **`extra[:id_token_claims]`** — デバッグや拡張用の ID トークンクレーム全体

## Auth Hash

```ruby
{
  uid: 'U02fa1e93...',
  info: {
    name: '表示名',
    image: 'https://profile.line-scdn.net/...',
    description: 'ステータスメッセージ',
    email: 'user@example.com',        # 追加
    email_verified: true               # 追加
  },
  extra: {
    raw_info: { ... },                 # LINE /v2/profile レスポンス
    id_token_claims: { ... }           # 追加: 検証済み ID トークンクレーム
  }
}
```

## エラーハンドリング

ID トークンが存在しない場合（`openid` スコープ未指定など）や verify API がエラーを返した場合、`email` と `email_verified` は `nil` になります。アプリケーション側で独自のメール収集フローにフォールバックできます。エラーは `OmniAuth.logger` で記録されます。

## Nonce 検証について

本 gem では nonce 検証は行いません。nonce のバリデーションが必要な場合は、`extra[:id_token_claims]['nonce']` から nonce を取得してコールバックコントローラーで検証してください。

## ライセンス

MIT License。詳細は [LICENSE](LICENSE) を参照してください。

オリジナル: [kazasiki/omniauth-line](https://github.com/kazasiki/omniauth-line)

リポジトリ: [buferago/omniauth-line](https://github.com/buferago/omniauth-line)
