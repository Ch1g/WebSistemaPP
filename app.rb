#encoding: utf-8
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'

configure do
	enable :sessions
end

helpers do
	def username
		session[:identity] ? session[:identity] : 'Hello stranger'
	end
end

get '/' do
	erb "Hello! <a href=\"https://github.com/bootstrap-ruby/sinatra-bootstrap\">Original</a> pattern has been modified for <a href=\"http://rubyschool.us/\">Ruby School</a>"			
end

get '/about' do
  erb :about
end

get '/visit' do
  erb :visit
end

post '/visit' do
  @visithash = {defecttype: params[:defecttype], defectinfo: params[:defectinfo]}
	@submit = true
	if @visithash[:defectinfo] == ''
		@message = "Заполните все поля!"
    @type = "alert-danger"
	else
		@message = "Спасибо! Ваша заявка принята в обработку."
    @type = "alert-success"
		f = File.open './public/main.txt', 'a'
		f.write "#{DateTime.now}: Тип неисправности: #{@visithash[:defecttype]}, Описание: #{@visithash[:defectinfo]}\n"
		f.close
  end
	erb :visit
end

get '/contacts' do
  erb :contacts
end

get '/login' do
  erb :login
end

post '/login' do
	session[:identity] = params['login']
	session[:password] = params['password']
	if session[:identity] == 'admin' && session[:password] == 'secret'
		where_user_came_from = session[:previous_url] || '/'
		redirect to where_user_came_from
	else
		@access = "Неверное имя пользователя или пароль"
		erb :login
	end
end

get '/logout' do
	session.delete(:identity)
	erb "<div class='alert alert-message'>Logged out</div>"
end