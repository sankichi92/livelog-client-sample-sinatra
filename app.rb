# frozen_string_literal: true

require 'json'
require 'net/http'
require 'securerandom'

require 'sinatra'

AUTHORIZATION_ENDPOINT = 'https://patient-bar-7812.auth0.com/authorize'
TOKEN_ENDPOINT = 'https://patient-bar-7812.auth0.com/oauth/token'

AUDIENCE = 'https://livelog.ku-unplugged.net/api/'

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
          <dt>Refresh Token</dt>
          <dd><%= session[:refresh_token] %></dd>
        </dl>
        <a href="/authorize">Get access token</a>
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
    scope: 'offline_access read:lives',
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
  session[:refresh_token] = parsed_body['refresh_token'] if parsed_body['refresh_token']

  redirect to('/')
end
