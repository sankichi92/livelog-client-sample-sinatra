# frozen_string_literal: true

require 'json'
require 'net/http'
require 'securerandom'

require 'sinatra'

AUTHORIZATION_ENDPOINT = 'https://patient-bar-7812.auth0.com/authorize'
TOKEN_ENDPOINT = 'https://patient-bar-7812.auth0.com/oauth/token'

AUDIENCE = 'https://livelog.ku-unplugged.net/api/'
GRAPHQL_ENDPOINT = 'https://livelog.ku-unplugged.net/api/graphql'

# TODO: Replace CLIENT_ID and CLIENT_SECRET values.
CLIENT_ID = 'YOUR_CLIENT_ID'
CLIENT_SECRET = 'YOUR_CLIENT_SECRET'
CALLBACK_URL = 'http://localhost:4567/callback'

enable :sessions

template :index do
  <<~HTML
    <!DOCTYPE html>
    <html>
      <head>
        <title>livelog-client-sample-sinatra</title>
      </head>
      <body>
        <dl>
          <dt>Access Token</dt>
          <dd><%= session[:access_token] %></dd>
        </dl>
        <a href="/authorize">Get access token</a>
        <a href="/live_albums">Get live album urls</a>
      </body>
    </html>
  HTML
end

get '/' do
  erb :index
end

get '/authorize' do
  session[:state] = SecureRandom.urlsafe_base64

  authorization_uri = URI.parse(AUTHORIZATION_ENDPOINT)
  authorization_uri.query = build_query(
    audience: AUDIENCE,
    response_type: 'code',
    client_id: CLIENT_ID,
    redirect_uri: CALLBACK_URL,
    scope: 'read:lives',
    state: session[:state]
  )

  redirect authorization_uri
end

get '/callback' do
  if params[:state] != session[:state]
    halt 400, "State does not match: expected '#{session[:state]}' got '#{escape(params[:state])}'"
  elsif params[:error]
    halt escape(params[:error])
  end

  response = Net::HTTP.post_form(
    URI.parse(TOKEN_ENDPOINT),
    {
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      grant_type: 'authorization_code',
      code: params[:code],
      redirect_uri: CALLBACK_URL
    }
  )
  response.value

  logger.info response.body
  parsed_body = JSON.parse(response.body)
  session[:access_token] = parsed_body['access_token']

  redirect to('/')
end

get '/live_albums' do
  graphql_query = <<~GRAPHQL
    query {
      lives {
        nodes {
          albumUrl
        }
      }
    }
  GRAPHQL

  uri = URI.parse(GRAPHQL_ENDPOINT)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  response = http.post(
    uri.path,
    build_query(query: graphql_query),
    { 'Authorization' => "Bearer #{session[:access_token]}" }
  )
  logger.info response.body

  case response
  when Net::HTTPSuccess
    parsed_body = JSON.parse(response.body)
    if parsed_body['errors']
      halt parsed_body['errors'].to_s
    else
      album_urls = parsed_body['data']['lives']['nodes'].map { |live| live['albumUrl'] }.compact
      halt album_urls.join(', ')
    end
  else
    halt "Unable to fetch live albums: #{response.code} #{response.message}"
  end
end
