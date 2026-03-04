require 'spec_helper'

describe OmniAuth::Strategies::Line do
  let(:request) { double('Request', params: {}, cookies: {}, env: {}) }
  let(:access_token) do
    double('AccessToken',
      params: { 'id_token' => 'dummy.id.token' },
      get: double('Response', body: raw_info_hash.to_json)
    )
  end

  subject do
    args = ['channel_id', 'channel_secret', @options || {}].compact
    OmniAuth::Strategies::Line.new(*args).tap do |strategy|
      allow(strategy).to receive(:request) { request }
      allow(strategy).to receive(:access_token) { access_token }
    end
  end

  describe 'client options' do
    it 'should have correct name' do
      expect(subject.options.name).to eq('line')
    end

    it 'should have correct site' do
      expect(subject.options.client_options.site).to eq('https://access.line.me')
    end

    it 'should have correct authorize url' do
      expect(subject.options.client_options.authorize_url).to eq('/oauth2/v2.1/authorize')
    end

    it 'should have correct token url' do
      expect(subject.options.client_options.token_url).to eq('/oauth2/v2.1/token')
    end
  end

  describe 'uid' do
    it 'returns the userId from raw_info' do
      stub_verify_api(verify_response_hash)
      expect(subject.uid).to eq(raw_info_hash['userId'])
    end
  end

  describe 'info' do
    before do
      stub_verify_api(verify_response_hash)
    end

    it 'returns the name' do
      expect(subject.info[:name]).to eq(raw_info_hash['displayName'])
    end

    it 'returns the image' do
      expect(subject.info[:image]).to eq(raw_info_hash['pictureUrl'])
    end

    it 'returns the description' do
      expect(subject.info[:description]).to eq(raw_info_hash['statusMessage'])
    end
  end

  describe 'email from ID Token' do
    context 'when verify API returns email with email_verified: true' do
      before do
        stub_verify_api(verify_response_hash)
      end

      it 'returns email from id_token_claims' do
        expect(subject.info[:email]).to eq('user@example.com')
      end

      it 'returns email_verified as true' do
        expect(subject.info[:email_verified]).to eq(true)
      end

      it 'exposes id_token_claims in extra' do
        expect(subject.extra[:id_token_claims]).to include('email' => 'user@example.com')
      end
    end

    context 'when email_verified is false' do
      before do
        stub_verify_api(verify_response_hash.merge('email_verified' => false))
      end

      it 'returns email' do
        expect(subject.info[:email]).to eq('user@example.com')
      end

      it 'returns email_verified as false' do
        expect(subject.info[:email_verified]).to eq(false)
      end
    end

    context 'when id_token is not present in access_token params' do
      let(:access_token) do
        double('AccessToken',
          params: {},
          get: double('Response', body: raw_info_hash.to_json)
        )
      end

      it 'returns nil for email' do
        expect(subject.info[:email]).to be_nil
      end

      it 'returns nil for email_verified' do
        expect(subject.info[:email_verified]).to be_nil
      end

      it 'does not call verify API' do
        subject.info
        expect(WebMock).not_to have_requested(:post, 'https://api.line.me/oauth2/v2.1/verify')
      end
    end

    context 'when id_token is empty string' do
      let(:access_token) do
        double('AccessToken',
          params: { 'id_token' => '' },
          get: double('Response', body: raw_info_hash.to_json)
        )
      end

      it 'returns nil for email' do
        expect(subject.info[:email]).to be_nil
      end
    end

    context 'when verify API returns HTTP 400' do
      before do
        stub_request(:post, 'https://api.line.me/oauth2/v2.1/verify')
          .to_return(status: 400, body: '{"error":"invalid_request"}')
      end

      it 'returns nil for email' do
        expect(subject.info[:email]).to be_nil
      end

      it 'does not raise an error' do
        expect { subject.info }.not_to raise_error
      end
    end

    context 'when verify API times out' do
      before do
        stub_request(:post, 'https://api.line.me/oauth2/v2.1/verify')
          .to_raise(Net::ReadTimeout)
      end

      it 'returns nil for email' do
        expect(subject.info[:email]).to be_nil
      end

      it 'does not raise an error' do
        expect { subject.info }.not_to raise_error
      end
    end

    context 'when verify API returns invalid JSON' do
      before do
        stub_request(:post, 'https://api.line.me/oauth2/v2.1/verify')
          .to_return(status: 200, body: 'not json at all')
      end

      it 'returns nil for email' do
        expect(subject.info[:email]).to be_nil
      end

      it 'does not raise an error' do
        expect { subject.info }.not_to raise_error
      end
    end

    context 'when scope does not include email (no email in claims)' do
      before do
        stub_verify_api(verify_response_hash.reject { |k, _| k == 'email' || k == 'email_verified' })
      end

      it 'returns nil for email' do
        expect(subject.info[:email]).to be_nil
      end

      it 'returns nil for email_verified' do
        expect(subject.info[:email_verified]).to be_nil
      end
    end
  end

  describe 'request_phase' do
    context 'with no request params set' do
      before do
        allow(subject).to receive(:request).and_return(
          double('Request', params: {})
        )
        allow(subject).to receive(:request_phase).and_return(:whatever)
      end

      it 'should not break' do
        expect { subject.request_phase }.not_to raise_error
      end
    end
  end
end

def raw_info_hash
  {
    'userId'        => 'U02fa1e93abcdef',
    'displayName'   => 'Foo Bar',
    'pictureUrl'    => 'http://xxx.com/aaa.jpg',
    'statusMessage' => 'Developer'
  }
end

def verify_response_hash
  {
    'iss'            => 'https://access.line.me',
    'sub'            => 'U02fa1e93abcdef',
    'aud'            => 'channel_id',
    'exp'            => 1700000000,
    'iat'            => 1699999000,
    'email'          => 'user@example.com',
    'email_verified' => true
  }
end

def stub_verify_api(response_body)
  stub_request(:post, 'https://api.line.me/oauth2/v2.1/verify')
    .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })
end
