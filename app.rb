# frozen_string_literal: true

require 'sinatra'

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
