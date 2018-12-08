require 'sinatra'
require 'sequel'
require 'pg'
require "sinatra/config_file"
require "sinatra/content_for"

config_file 'locales/*.yml'

configure do
  db = URI.parse(ENV['DATABASE_URL'])
  DB = Sequel.connect(adapter: :postgres, host: db.host, user: db.user, database: db.database, password: db.password)
end

enable :sessions

get '/' do
  slim :home, layout: false, locals: { l: settings.ua }
end

get '/admin' do
  slim :admin, layout: false, locals: { post: DB[:posts].where(id: params[:post]).first || {title: '', lang: 1, text: ''} }
end

get '/news/?' do
  slim :news, locals: { news: DB[:posts].where(lang: 0), locale: 'en' , l: settings.en }
end

get '/новини/?' do
  slim :news, locals: { news: DB[:posts].where(lang: 1), locale: 'ua' , l: settings.ua  }
end

get '/новости/?' do
  slim :news, locals: { news: DB[:posts].where(lang: 2), locale: 'ru' , l: settings.ru  }
end

post '/post' do
  redirect '/' unless session[:login]
  if params[:id].empty?
    DB[:posts].insert(title: params[:title], text: params[:text], image: params[:image], lang: params[:lang].to_i)
  else
    DB[:posts].where(id: params[:id]).update(title: params[:title], text: params[:text], image: params[:image], lang: params[:lang].to_i)
  end
  redirect '/'
end

post '/login' do
  session[:login] = true if params[:password] == ENV["PASSWORD"]
  redirect '/admin'
end

get '/delete/:id' do
  redirect '/' unless session[:login]
  DB[:posts].where(id: params[:id]).delete
  redirect '/'
end

get /\/(en|ua|ru)\/?/ do
  slim :home, layout: false, locals: { l: settings.send(params['captures'].first) }
end

get '/google843e00e5e643230e.html' do
  send_file 'views/google.html'
end

get '/favicon.ico' do
  send_file 'public/images/favicon-16x16.png'
end

get '/*' do
  begin
    slim :"pages/#{params[:splat].first}"
  rescue
    status 404
  end
end
