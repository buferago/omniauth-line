require 'omniauth-oauth2'
require 'json'
require 'net/http'
require 'uri'

module OmniAuth
  module Strategies
    class Line < OmniAuth::Strategies::OAuth2
      option :name, 'line'
      option :scope, 'profile openid'

      option :client_options, {
        site: 'https://access.line.me',
        authorize_url: '/oauth2/v2.1/authorize',
        token_url: '/oauth2/v2.1/token'
      }

      # LINE API のベース URL が認可とリソースで異なるため、
      # callback 時に api.line.me に切り替える（本家踏襲）
      def callback_phase
        options[:client_options][:site] = 'https://api.line.me'
        super
      end

      def callback_url
        options[:callback_url] || (full_host + script_name + callback_path)
      end

      uid { raw_info['userId'] }

      info do
        {
          name:           raw_info['displayName'],
          image:          raw_info['pictureUrl'],
          description:    raw_info['statusMessage'],
          email:          id_token_claims['email'],
          email_verified: id_token_claims['email_verified']
        }
      end

      extra do
        {
          raw_info: raw_info,
          id_token_claims: id_token_claims
        }
      end

      def raw_info
        @raw_info ||= JSON.parse(access_token.get('v2/profile').body)
      rescue ::Errno::ETIMEDOUT
        raise ::Timeout::Error
      end

      private

      VERIFY_URL = URI('https://api.line.me/oauth2/v2.1/verify')

      # LINE /oauth2/v2.1/verify API で ID Token をサーバー側検証し、クレームを取得
      # access_token オブジェクトに依存せず、Net::HTTP で直接呼び出す（site 依存を排除）
      # エラー時は空ハッシュを返しフォールバック（メール入力フローへ）
      def id_token_claims
        return @id_token_claims if defined?(@id_token_claims)

        id_token = access_token.params&.[]('id_token')
        if id_token.nil? || id_token.to_s.empty?
          return @id_token_claims = {}
        end

        resp = Net::HTTP.post_form(VERIFY_URL, {
          id_token: id_token,
          client_id: options.client_id
        })

        unless resp.is_a?(Net::HTTPSuccess)
          log(:warn, "LINE verify API returned #{resp.code}: #{resp.body}")
          return @id_token_claims = {}
        end

        @id_token_claims = JSON.parse(resp.body)
      rescue JSON::ParserError, Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED => e
        log(:warn, "LINE ID Token verification failed: #{e.class} - #{e.message}")
        @id_token_claims = {}
      end

      def log(level, message)
        OmniAuth.logger.send(level, "(line) #{message}") if OmniAuth.logger
      end
    end
  end
end
