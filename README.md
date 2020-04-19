# livelog-client-sample-sinatra

[LiveLog API](https://github.com/sankichi92/LiveLog/wiki) のサンプルクライアントアプリです。  
Authorization Code フローでアクセストークンを取得し、LiveLog API を叩きます。

## 使い方

1. https://livelog.ku-unplugged.net/clients/new から "Regular Web Application" タイプのアプリケーションを作成する
2. Callback URL に http://localhost:4567/callback を設定する
3. `app.rb` を開き、定数 `CLIENT_ID` と `CLIENT_SECRET` を 1. で作成したアプリケーションのものに置き換える
4. `bundle install` で [Sinatra](http://sinatrarb.com/) をインストールする
5. `bundle exec ruby app.rb` で Web サーバーを起動する
6. http://localhost:4567 にアクセスし、"Get access token" をクリックする
7. LiveLog アカウントでサンプルアプリを認可し、アクセストークンを取得する
8. "Get live albums urls" をクリックする
9. LiveLog のアルバム URL が確認できる
