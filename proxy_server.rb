require "sinatra"
require "httparty"
require "json"
require "base64"
require "puma"
set :server, "puma"

# Configure Sinatra to allow CORS requests
configure do
  set :bind, "0.0.0.0"
  set :port, 8080
  set :protection, except: :path_traversal
end

before do
  headers["Access-Control-Allow-Origin"] = "*"
  headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
  headers[
    "Access-Control-Allow-Headers"
  ] = "Authorization, Content-Type, Accept, X-Requested-With, X-HTTP-Method-Override"
end

options "/*" do
  200
end

# Basic Authentication
helpers do
  def protected!
    return if authorized?
    headers["WWW-Authenticate"] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized"
  end

  def authorized?
    @auth ||= Rack::Auth::Basic::Request.new(request.env)
    return false unless @auth.provided? && @auth.basic? && @auth.credentials

    username, password = @auth.credentials
    username == ENV["CORS_PROXY_USERNAME"] &&
      password == ENV["CORS_PROXY_PASSWORD"]
  end
end

# Proxy GET request
get "/*" do
  protected!

  response = HTTParty.get(params["splat"].first)
  response.body
end

# Proxy POST request
post "/*" do
  protected!
  response = HTTParty.post(params["splat"].first, body: request.body.read)
  response.body
end

# Proxy PUT request
put "/*" do
  protected!
  response = HTTParty.put(params["splat"].first, body: request.body.read)
  response.body
end

# Proxy DELETE request
delete "/*" do
  protected!
  response = HTTParty.delete(params["splat"].first)
  response.body
end

# curl -X GET "http://user:password@localhost:8080/https://jsonplaceholder.typicode.com/todos/1"
