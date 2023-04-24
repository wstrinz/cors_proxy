require 'rspec'
require 'rack/test'
require_relative '../proxy_server'
require 'webmock/rspec'

ENV['RACK_ENV'] = 'test'

RSpec.configure do |config|
  config.include WebMock::API
end

describe 'Proxy Server' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  let(:username) { ENV['CORS_PROXY_USERNAME'] }
  let(:password) { ENV['CORS_PROXY_PASSWORD'] }
  let(:credentials) { Base64.strict_encode64("#{username}:#{password}") }

  describe 'GET request' do
    it 'requires authentication' do
      get '/https://api.example.com/data'
      expect(last_response.status).to eq(401)
    end

    it 'proxies a GET request' do
      stub_request(:get, 'https://api.example.com/data')
        .to_return(status: 200, body: { message: 'Hello, World!' }.to_json)

      get '/https://api.example.com/data', {}, { 'HTTP_AUTHORIZATION' => "Basic #{credentials}" }
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq('message' => 'Hello, World!')
    end
  end

  describe 'POST request' do
    it 'requires authentication' do
      post '/https://api.example.com/data'
      expect(last_response.status).to eq(401)
    end

    it 'proxies a POST request' do
      stub_request(:post, 'https://api.example.com/data')
        .with(body: { message: 'Hello, World!' }.to_json)
        .to_return(status: 200, body: { status: 'Created' }.to_json)

      post '/https://api.example.com/data', { message: 'Hello, World!' }.to_json, { 'HTTP_AUTHORIZATION' => "Basic #{credentials}", 'CONTENT_TYPE' => 'application/json' }
      expect(last_response.status).to eq(201)
      expect(JSON.parse(last_response.body)).to eq('status' => 'Created')
    end
  end

  # Add similar tests for PUT and DELETE requests
end
