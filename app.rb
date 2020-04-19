# frozen_string_literal: true

require 'securerandom'

require 'sinatra'

AUTHORIZATION_ENDPOINT = 'https://patient-bar-7812.auth0.com/authorize'

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
    state: session[:state],
    prompt: 'none'
  )

  redirect authorization_uri
end
