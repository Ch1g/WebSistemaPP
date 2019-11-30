#encoding: utf-8
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/activerecord'
require './crud'

configure do
	enable :sessions
end

not_found do
  erb :not_found
end

helpers do
	def username
		session[:identity] ? session[:identity] : 'Гость'
	end

	def get_db
		@db = SQLite3::Database.new './database/blohstreet.db'
		@db.results_as_hash = true
	end
end

get '/' do
	erb "<h2 class = 'text-center'>Hello!</h2><p class = 'text-center'>Добро пожаловать!</p>"
end

get '/registration' do
	if session[:identity]
		erb "<div class='alert alert-danger text-center'>Вы уже авторизованы! Вам это не нужно! </div>"
	else
		erb :registration
	end
end

post '/registration' do
	@reload = {login: params[:User_Login], password: params[:User_Password], role: CRUD::Role.find_by(name: 'Клиент').id_role,
             name: params[:User_Name], surname: params[:User_Surname], patronymic: params[:User_Patronymic],
             phone: params[:User_Phone], post: CRUD::Post.find_by(name: 'Клиент').id_post,
						 pavilion: params[:Pavilion_Select].split[0].chomp('.')}
  case
  when @reload[:login] == ''||@reload[:password] == ''||@reload[:name] == ''||@reload[:surname] == ''||@reload[:patronymic] == ''||@reload[:phone] == ''
		@message = ['alert-danger','Необходимо заполнить все поля!']
  when CRUD::User.find_by(phone: @reload[:phone])
		@message = ['alert-danger','Введенный вами номер телефона уже используется!']
  when 16 < params[:User_Login].length
		@message = ['alert-danger','Имя пользователя должно содержать не более 16 символов']
  when CRUD::User.find_by(login: @reload[:login])
		@message = ['alert-danger','Пользователь с таким логином уже существует в базе!']
  when	((6..16).include? params[:User_Password])
		@message = ['alert-danger','Пароль должен содержать от 6 до 16 символов!']
  when params[:User_Password] != params[:User_Password2]
		@message = ['alert-danger','Пароли не совпадают!']
	else
		CRUD::User.create @reload
		@reload = {}
		@message = ['alert-success','Регистрация успешна!']
  end
  erb :registration
end

get '/tables/:value' do
	if CRUD::Role.find(CRUD::User.find_by(login: session[:identity]).role).name == 'Администратор'
    $message && $message[2] ? $message[2] = false : $message = nil
		get_db
    @table = params[:value]
    @tables = @db.execute "SELECT name FROM sqlite_master
								WHERE type='table'
								and name != 'sqlite_sequence'
								and name != 'schema_migrations'
								and name != 'ar_internal_metadata'
								ORDER BY name;"
		@db.close
    else
			redirect to not_found
    end
	erb :tables
end

get '/tables/:table/:id/delete' do
  table = params[:table]
	id = params[:id]
  case table
  when 'pavilions'
    CRUD::User.find_by(pavilion: id) ? success = false : CRUD::Pavilion.find(id).delete
  when 'defects'
    CRUD::Maintenance.find_by(defect: id) ? success = false : CRUD::Defect.find(id).delete
	when 'maintenances'
		CRUD::Maintenance.find(id).delete
  when 'posts'
    CRUD::User.find_by(post: id) ? success = false : CRUD::Post.find(id).delete
  when 'roles'
    CRUD::User.find_by(role: id) ? success = false : CRUD::Role.find(id).delete
  when 'statuses'
    CRUD::Maintenance.find_by(status: id) ? success = false : CRUD::Status.find(id).delete
	when 'users'
		CRUD::Maintenance.find_by(client: id ) || CRUD::Maintenance.find_by(executor: id ) ? success = false : CRUD::User.find(id).delete
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

get '/account' do
	if session[:identity]
		erb :account
	else
		redirect to '/login'
	end

end

get '/visit' do
  erb :visit
end

post '/account' do
	if username == 'Hello stranger'
		erb :login
  else
    case
    when params[:current_password] != CRUD::User.find_by(login: username).password
      @message = ['alert-danger', 'Текущий пароль указан неверно']
    when !((6..16).include? params[:new_password].length)
			@message = ['alert-danger', 'Пароль должен содержать от 6 до 16 символов']
    when params[:new_password] != params[:new_password2]
			@message = ['alert-danger', 'Пароли не совпадают']
    else
      @message = ['alert-success', 'Пароль успешно изменен']
      CRUD::User.update(CRUD::User.find_by(login: username).id_user, password: params[:new_password])
    end
    @last = "Settings"
    erb :account
    end
end

post '/visit' do
  @reload = {defect: params[:Defect_Select].split[0].chomp, description: params[:Defect_Descr],
             client: CRUD::User.find_by(login: session[:identity]).id_user, bid_date: DateTime.now.strftime("%Y-%m-%d %H:%M:%S"),
             status: CRUD::Status.find_by(name: 'Не готово').id_status}
	if @reload[:defectinfo] == ''
		@message = ["alert-danger", "Заполните информацию о неисправности!"]
  else
    CRUD::Maintenance.create @reload
		@message = ["alert-success", "Спасибо! Ваша заявка принята в обработку."]
  end
	erb :visit
end

get '/tables/:table/new' do
	@table = params[:table]
	erb :insert
end

post '/tables/:table/new' do
  @table = params[:table]
  case @table
  when 'pavilions'
    @reload = {square: params[:Pavilion_Square], floors: params[:Pavilion_Floors], number: params[:Pavilion_Num]}
    if CRUD::Pavilion.find_by(number: @reload[:number])
      @message = ['alert-danger','Данный номер павильона уже используется в базе!']
    elsif params[:Pavilion_Square] == '' or params[:Pavilion_Floors] == '' or params[:Pavilion_Num] == ''
      @message = ['alert-danger','Необходимо заполнить все поля!']
    else
      CRUD::Pavilion.create @reload
			@reload = {}
			@message = ['alert-success','Запись успешно добавлена!']
    end
  when 'defects'
		@reload = {defect_name: params[:Defect_Type]}
		if CRUD::Defect.find_by(defect_name: @reload[:defect_name])
			@message = ['alert-danger','Данный тип уже существует в базе!']
		elsif @reload[:defect_name] == ''
			@message = ['alert-danger','Необходимо заполнить поле!']
		else
			CRUD::Defect.create @reload
			@reload = {}
			@message = ['alert-success','Запись успешно добавлена!']
    end
	when 'posts'
		@reload = {name: params[:Post_Name]}
		if CRUD::Post.find_by(name: @reload[:name])
			@message = ['alert-danger','Данная должность уже существует в базе!']
		elsif @reload[:name] == ''
			@message = ['alert-danger','Необходимо заполнить поле!']
		else
			CRUD::Post.create @reload
			@reload = {}
			@message = ['alert-success','Запись успешно добавлена!']
    end
	when 'roles'
		@reload = {name: params[:Role_Name], defect: params[:Defect_T]? true : false,
               status: params[:Status_T]? true : false, maintenance: params[:Main_T]? true : false,
               pavilion: params[:Status_T]? true : false, post: params[:Post_T]? true : false}
		if CRUD::Role.find_by(name: @reload[:name])
			@message = ['alert-danger','Данная роль уже существует в базе!']
		elsif @reload[:name] == ''
			@message = ['alert-danger','Необходимо заполнить поле!']
		else
			CRUD::Role.create @reload
			@reload = {}
			@message = ['alert-success','Запись успешно добавлена!']
    end
	when 'statuses'
		@reload = {name: params[:Status_Name]}
		if CRUD::Status.find_by(name: @reload[:name])
			@message = ['alert-danger','Данный статус уже существует в базе!']
		elsif @reload[:name] == ''
			@message = ['alert-danger','Необходимо заполнить поле!']
		else
			CRUD::Status.create @reload
      @reload = {}
			@message = ['alert-success','Запись успешно добавлена!']
    end
	when 'users'
		@reload = {login: params[:User_Login], password: params[:User_Password], role: params[:Role_Select].split[0].chomp('.'), name: params[:User_Name],
               surname: params[:User_Surname], patronymic: params[:User_Patronymic], phone: params[:User_Phone], post: params[:Post_Select].split[0].chomp('.'),
               pavilion: params[:Pavilion_Select].split[0].chomp('.')}
    case
  	when @reload[:login] == '' || @reload[:password] == '' || @reload[:name] == '' || @reload[:surname] == '' || @reload[:patronymic] == '' || @reload[:phone] == ''
      @message = ['alert-danger','Необходимо заполнить все поля!']
    when CRUD::User.find_by(login: @reload[:login])
      @message = ['alert-danger','Пользователь с таким логином уже существует в базе!']
    when CRUD::User.find_by(phone: @reload[:phone])
			@message = ['alert-danger','Введенный вами номер телефона уже используется!']
    when	((6..16).include? @reload[:password])
			@message = ['alert-danger','Пароль должен содержать от 6 до 16 символов!']
		else
			CRUD::User.create @reload
			@reload = {}
			@message = ['alert-success','Запись успешно добавлена!']
    end
  when 'maintenances'
    @reload = {status: params[:Status_Select].split[0].chomp('.'), executor: params[:Executor_Select].split[0].chomp('.'),
               client: params[:Client_Select].split[0].chomp('.'), bid_date: params[:Date_Bid], end_date: params[:Date_End],
               defect: params[:Defect_Select].split[0].chomp('.'), description: params[:Maintenance_Descr]}
    if @reload[:bid_date] == ''
			@message = ['alert-danger','Дата и время подачи заявки должны быть указаны!']
    elsif @reload[:description] == '' or @reload[:description].length > 255
			@message = ['alert-danger','Описание не должно быть пустым или превышать 255 символов!']
    else
			CRUD::Maintenance.create @reload
			@reload = {}
			@message = ['alert-success','Запись успешно добавлена!']
    end
  end
  erb :insert
end

post '/tables/:table/:id/update' do
	@table = params[:table]
  @id = params[:id]
	case @table
	when 'pavilions'
		@reload = {square: params[:Pavilion_Square], floors: params[:Pavilion_Floors]}
		if params[:Pavilion_Square] == '' or params[:Pavilion_Floors] == '' or params[:Pavilion_Num] == ''
			@message = ['alert-danger','Необходимо заполнить все поля!']
		else
			CRUD::Pavilion.update(@id, @reload)
			@reload = {}
			@message = ['alert-success','Запись успешно обновлена!']
		end
	when 'defects'
		@reload = {defect_name: params[:Defect_Type]}
		if CRUD::Defect.find_by(defect_name: @reload[:defect_name])
			@message = ['alert-danger','Данный тип уже существует в базе!']
		elsif @reload[:defect_name] == ''
			@message = ['alert-danger','Необходимо заполнить поле!']
		else
			CRUD::Defect.update(@id, @reload)
			@reload = {}
			@message = ['alert-success','Запись успешно обновлена!']
		end
	when 'posts'
		@reload = {name: params[:Post_Name]}
		if CRUD::Post.find_by(name: @reload[:name])
			@message = ['alert-danger','Данная должность уже существует в базе!']
		elsif @reload[:name] == ''
			@message = ['alert-danger','Необходимо заполнить поле!']
		else
			CRUD::Post.update(@id, @reload)
			@reload = {}
			@message = ['alert-success','Запись успешно обновлена!']
		end
	when 'roles'
		@reload = {defect: params[:Defect_T]? true : false,
							 status: params[:Status_T]? true : false, maintenance: params[:Main_T]? true : false,
							 pavilion: params[:Status_T]? true : false, post: params[:Post_T]? true : false}
		if @reload[:name] == ''
			@message = ['alert-danger','Необходимо заполнить поле!']
		else
			CRUD::Role.update(@id, @reload)
			@reload = {}
			@message = ['alert-success','Запись успешно обновлена!']
		end
	when 'statuses'
		@reload = {name: params[:Status_Name]}
		if CRUD::Status.find_by(name: @reload[:name])
			@message = ['alert-danger','Данный статус уже существует в базе!']
		elsif @reload[:name] == ''
			@message = ['alert-danger','Необходимо заполнить поле!']
		else
			CRUD::Status.update(@id, @reload)
			@reload = {}
			@message = ['alert-success','Запись успешно обновлена!']
		end
	when 'users'
		@reload = {password: params[:User_Password], role: params[:Role_Select].split[0].chomp('.'), name: params[:User_Name],
							 surname: params[:User_Surname], patronymic: params[:User_Patronymic], phone: params[:User_Phone], post: params[:Post_Select].split[0].chomp('.'),
							 pavilion: params[:Pavilion_Select].split[0].chomp('.')}
    case
		when @reload[:login] == '' || @reload[:password] == '' || @reload[:name] == '' || @reload[:surname] == '' || @reload[:patronymic] == '' || @reload[:phone] == ''
			@message = ['alert-danger','Необходимо заполнить все поля!']
		when CRUD::User.find_by(login: @reload[:login])
			@message = ['alert-danger','Пользователь с таким логином уже существует в базе!']
		when CRUD::User.find_by(phone: @reload[:phone])
			@message = ['alert-danger','Введенный вами номер телефона уже используется!']
		when	((6..16).include? @reload[:password])
			@message = ['alert-danger','Пароль должен содержать от 6 до 16 символов!']
		else
			CRUD::User.update(@id, @reload)
			@reload = {}
			@message = ['alert-success','Запись успешно обновлена!']
		end
	when 'maintenances'
		@reload = {status: params[:Status_Select].split[0].chomp('.'), executor: params[:Executor_Select].split[0].chomp('.'),
							 client: params[:Client_Select].split[0].chomp('.'), bid_date: params[:Date_Bid], end_date: params[:Date_End],
							 defect: params[:Defect_Select].split[0].chomp('.'), description: params[:Maintenance_Descr]}
		if @reload[:bid_date] == ''
			@message = ['alert-danger','Дата и время подачи заявки должны быть указаны!']
		elsif @reload[:description] == '' or @reload[:description].length > 255
			@message = ['alert-danger','Описание не должно быть пустым или превышать 255 символов!']
		else
			CRUD::Maintenance.update(@id, @reload)
			@reload = {}
			@message = ['alert-success','Запись успешно обновлена!']
		end
	end
	erb :update
end

get '/tables/:table/:id/update' do
  @id = params[:id]
	@table = params[:table]
	case @table
	when 'pavilions'
		@reload = CRUD::Pavilion.find(@id)
	when 'defects'
		@reload = CRUD::Defect.find(@id)
	when 'posts'
		@reload = CRUD::Post.find(@id)
	when 'roles'
		@reload = CRUD::Role.find(@id)
	when 'statuses'
		@reload = CRUD::Status.find(@id)
	when 'users'
		@reload = CRUD::User.find(@id)
	when 'maintenances'
		@reload = CRUD::Maintenance.find(@id)
	end
	erb :update
end

get '/login' do
	if session[:identity]
		erb "<div class='alert alert-danger text-center'>Вы уже авторизованы!</div>"
	else
		erb :login
	end
end


post '/login' do
	if  params[:pass] == CRUD::User.find_by(login: params[:login]).password
		session[:identity] = params[:login]
		erb "<div class='alert alert-success text-center'>Авторизация успешна!</div>"
	else
		@access = "Неверное имя пользователя или пароль"
		erb :login
	end
end

get '/logout' do
	if !session[:identity]
		erb "<div class='alert alert-danger text-center'>Чтобы выйти следует прежде авторизоваться!</div>"
	else
		session.delete(:identity)
		erb "<div class='alert alert-success text-center'>До свидания!</div>"
  end
end