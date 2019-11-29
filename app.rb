#encoding: utf-8
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/activerecord'
require './crud'

configure do
	enable :sessions
end

helpers do
	def username
		session[:identity] ? session[:identity] : 'Hello stranger'
	end

	def get_db
		@db = SQLite3::Database.new './database/blohstreet.db'
		@db.results_as_hash = true
	end
end

get '/' do
	erb "<h2>Hello!</h2><p>Добро пожаловать!</p>"
end

get '/tables/:value' do
  $message[2] ? $message[2] = false : $message = nil if $message
  get_db
	@table = params[:value]
	@tables = @db.execute "SELECT name FROM sqlite_master
            WHERE type='table'
						and name != 'sqlite_sequence'
					 	and name != 'schema_migrations'
						and name != 'ar_internal_metadata'
            ORDER BY name;"
	case @table
  when 'pavilions'
    @glob = CRUD::Pavilion.all
  when 'defects'
    @glob = CRUD::Defect.all
  when 'maintenances'
    @glob = CRUD::Maintenance.all
  when 'posts'
    @glob = CRUD::Post.all
  when 'roles'
    @glob = CRUD::Role.all
  when 'statuses'
    @glob = CRUD::Status.all
  when 'users'
    @glob = CRUD::User.all
  end
	@db.close
	erb :tables
end

get '/tables/:table/:id/delete' do
  table = params[:table]
	id = params[:id]
  case table
  when 'pavilions'
    pavilionfk = CRUD::User.find_by(pavilion: id)
		pavilionfk ? success = false : CRUD::Pavilion.find(id).delete
  when 'defects'
    defectfk = CRUD::Maintenance.find_by(defect: id)
		defectfk ? success = false : CRUD::Defect.find(id).delete
	when 'maintenances'
		CRUD::Maintenance.find(id).delete
  when 'posts'
    postfk = CRUD::User.find_by(post: id)
		postfk ? success = false : CRUD::Post.find(id).delete
  when 'roles'
    rolefk = CRUD::User.find_by(role: id)
		rolefk ? success = false : CRUD::Role.find(id).delete
  when 'statuses'
    statusfk = CRUD::Maintenance.find_by(status: id)
		statusfk ? success = false : CRUD::Status.find(id).delete
	when 'users'
		clientfk = CRUD::Maintenance.find_by(client: id )
    execfk = CRUD::Maintenance.find_by(executor: id )
    clientfk or execfk ? success = false : CRUD::User.find(id).delete
    end
  if success == nil
		$message = ["Запись успешно удалена!",
								"alert-success"]
  else
		$message = ["Прежде, чем удалить данную запись, следует удалить ее связь с другой таблицей!",
								"alert-danger"]
  end
	$message[2] = true
	redirect to "/tables/#{table}"
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
  end
	erb :visit
end

get '/tables/:table/new' do
	@table = params[:table]
	erb :insert
end

get '/login' do
	if session[:identity]
		erb "<div class='alert alert-danger text-center'>Вы уже авторизованы!</div>"
	else
		erb :login
	end
end


post '/login' do
	pass = @db.execute "select password, login from User where User_login = ?", params[:login]
	@db.close
	if  params[:pass] == pass[0]["password"] && params[:login] == pass[0]["login"]
		session[:identity] = params[:login]
		erb "<div class='alert alert-success text-center'>Авторизация успешна!</div>"
	else
		@access = "Неверное имя пользователя или пароль"
		erb :login
	end
rescue
	@access = "Неверное имя пользователя или пароль"
	erb :login
end

get '/logout' do
	if username == 'Hello stranger'
		erb "<div class='alert alert-danger text-center'>Чтобы выйти следует прежде авторизоваться!</div>"
	else
		session.delete(:identity)
		erb "<div class='alert alert-success text-center'>До свидания!</div>"
	end
end