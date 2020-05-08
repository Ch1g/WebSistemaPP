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
  case
  when CRUD::User.find_by(phone: params[:User_Phone])
		@message = ['alert-danger','Введенный вами номер телефона уже используется!']
  when 16 < params[:User_Login].length
		@message = ['alert-danger','Имя пользователя должно содержать не более 16 символов']
  when CRUD::User.find_by(login: params[:User_Login])
		@message = ['alert-danger','Пользователь с таким логином уже существует в базе!']
  when	!((6..16).include? params[:User_Password].length)
		@message = ['alert-danger','Пароль должен содержать от 6 до 16 символов!']
  when params[:User_Password] != params[:User_Password2]
		@message = ['alert-danger','Пароли не совпадают!']
	else
		CRUD::User.create [login: params[:User_Login], password: params[:User_Password], role: CRUD::Role.find_by(name: 'Клиент').id_role,
				name: params[:User_Name], surname: params[:User_Surname], patronymic: params[:User_Patronymic],
				phone: params[:User_Phone], post: CRUD::Post.find_by(name: 'Клиент').id_post,
				pavilion: params[:Pavilion_Select].split[0].chomp('.')]
		@message = ['alert-success','Регистрация успешна!']
  end
  erb :registration
end

before '/tables/*' do
	unless session[:identity]
		@access = 'Подтвердите права доступа для посещения ' + request.path
		halt erb(:login)
	end
end

get '/tables/:value' do
  if CRUD::Role.find(CRUD::User.find_by(login: session[:identity]).role).name == 'Администратор'
    $message && $message[2] ? $message[2] = false : $message = nil
    @tables = ActiveRecord::Base.connection.tables - ["schema_migrations", "ar_internal_metadata"]
    erb :tables
  else
    erb :not_found
  end
end

get '/tables/:table/:id/delete' do
  if CRUD::Role.find(CRUD::User.find_by(login: session[:identity]).role).name == 'Администратор'
  case params[:table]
  when 'pavilions'
    CRUD::User.find_by(pavilion: params[:id]) ? success = false : CRUD::Pavilion.find(params[:id]).delete
  when 'defects'
    CRUD::Maintenance.find_by(defect: params[:id]) ? success = false : CRUD::Defect.find(params[:id]).delete
	when 'maintenances'
		CRUD::Maintenance.find(params[:id]).delete
  when 'posts'
    CRUD::User.find_by(post: params[:id]) ? success = false : CRUD::Post.find(params[:id]).delete
  when 'roles'
    CRUD::User.find_by(role: params[:id]) ? success = false : CRUD::Role.find(params[:id]).delete
  when 'statuses'
    CRUD::Maintenance.find_by(status: params[:id]) ? success = false : CRUD::Status.find(params[:id]).delete
	when 'users'
		CRUD::Maintenance.find_by(client: params[:id] ) || CRUD::Maintenance.find_by(executor: params[:id] ) ? success = false : CRUD::User.find(params[:id]).delete
    end
  $message = success == nil ? ["Запись успешно удалена!", "alert-success", true] :
                 										["Прежде, чем удалить данную запись, следует удалить ее связь с другой таблицей!", "alert-danger", true]
	redirect to "/tables/#{params[:table]}"
  else
    erb :not_found
  end
end

get '/about' do
  erb :about
end

get '/account' do
	session[:identity] ? (erb :account) : (redirect to('/login'))
end

post '/account/chpass' do
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

get '/visit' do
  if !session[:identity]
    erb :login
  elsif CRUD::Role.find(CRUD::User.find_by(login: session[:identity]).role).name == 'Клиент'
  	erb :visit
  else
    erb :not_found
  end
end

post '/visit' do
	if params[:Defect_Descr] == ''
		@message = ["alert-danger", "Заполните информацию о неисправности!"]
  else
    CRUD::Maintenance.create(defect: params[:Defect_Select].split[0].chomp, description: params[:Defect_Descr],
        client: CRUD::User.find_by(login: session[:identity]).id_user, bid_date: DateTime.now.strftime("%Y-%m-%d %H:%M:%S"),
        status: CRUD::Status.find_by(name: 'Не готово').id_status)
		@message = ["alert-success", "Спасибо! Ваша заявка принята в обработку."]
  end
	erb :visit
end

get '/tables/:table/new' do
  if session[:identity]&&CRUD::Role.find(CRUD::User.find_by(login: session[:identity]).role).name == 'Администратор'
	@table = params[:table]
	erb :insert
  else
    erb :not_found
  end
end

post '/tables/:table/new' do
  if CRUD::Role.find(CRUD::User.find_by(login: session[:identity]).role).name == 'Администратор'
  case params[:table]
  when 'pavilions'
    if CRUD::Pavilion.find_by(number: params[:Pavilion_Num])
      @message = ['alert-danger','Данный номер павильона уже используется в базе!']
    else
      CRUD::Pavilion.create(square: params[:Pavilion_Square], floors: params[:Pavilion_Floors], number: params[:Pavilion_Num])
    end
  when 'defects'
    if CRUD::Defect.create(defect_name: params[:Defect_Type])
      @message = ['alert-danger','Данный тип уже существует в базе!']
    end
	when 'posts'
		if CRUD::Post.find_by(name: params[:Post_Name])
			@message = ['alert-danger','Данная должность уже существует в базе!']
		else
			CRUD::Post.create(name: params[:Post_Name])
    end
	when 'roles'
		if CRUD::Role.find_by(name: params[:Role_Name])
			@message = ['alert-danger','Данная роль уже существует в базе!']
		else
			CRUD::Role.create(name: params[:Role_Name], defect: params[:Defect_T]? true : false,
												status: params[:Status_T]? true : false, maintenance: params[:Main_T]? true : false,
												pavilion: params[:Status_T]? true : false, post: params[:Post_T]? true : false)
    end
	when 'statuses'
		if CRUD::Status.find_by(name: params[:Status_Name])
			@message = ['alert-danger','Данный статус уже существует в базе!']
		else
			CRUD::Status.create(name: params[:Status_Name])
    end
	when 'users'
    case
    when CRUD::User.find_by(login: params[:User_Login])
      @message = ['alert-danger','Пользователь с таким логином уже существует в базе!']
    when CRUD::User.find_by(phone: params[:User_Phone])
			@message = ['alert-danger','Введенный вами номер телефона уже используется!']
    when	((6..16).include? params[:User_Password])
			@message = ['alert-danger','Пароль должен содержать от 6 до 16 символов!']
		else
			CRUD::User.create(login: params[:User_Login], password: params[:User_Password], role: params[:Role_Select].split[0].chomp('.'), name: params[:User_Name],
												surname: params[:User_Surname], patronymic: params[:User_Patronymic], phone: params[:User_Phone], post: params[:Post_Select].split[0].chomp('.'),
												pavilion: params[:Pavilion_Select].split[0].chomp('.'))
    end
  when 'maintenances'
    if params[:Maintenance_Descr].length > 255
			@message = ['alert-danger','Описание не должно быть пустым или превышать 255 символов!']
    else
			CRUD::Maintenance.create(status: params[:Status_Select].split[0].chomp('.'), executor: params[:Executor_Select].split[0].chomp('.'),
					client: params[:Client_Select].split[0].chomp('.'), bid_date: params[:Date_Bid], end_date: params[:Date_End],
					defect: params[:Defect_Select].split[0].chomp('.'), description: params[:Maintenance_Descr])
    end
  end
  redirect to "tables/#{params[:table]}"
  else
    erb :not_found
  end
end

post '/tables/:table/:id/update' do
  if CRUD::Role.find(CRUD::User.find_by(login: session[:identity]).role).name == 'Администратор'
	case params[:table]
	when 'pavilions'
			CRUD::Pavilion.update(params[:id], square: params[:Pavilion_Square], floors: params[:Pavilion_Floors])
      $message = ["Запись успешно изменена!", "alert-success", true]
			redirect to "/tables/#{params[:table]}"
	when 'defects'
		if CRUD::Defect.find_by(defect_name: params[:Defect_Type])
			@message = ['alert-danger','Данный тип уже существует в базе!']
      erb :update
		else
			CRUD::Defect.update(params[:id], defect_name: params[:Defect_Type])
      $message = ["Запись успешно изменена!", "alert-success", true]
			redirect to "/tables/#{params[:table]}"
		end
	when 'posts'
		if CRUD::Post.find_by(name: params[:Post_Name])
			@message = ['alert-danger','Данная должность уже существует в базе!']
			erb :update
		else
			CRUD::Post.update(params[:id], name: params[:Post_Name])
			$message = ["Запись успешно изменена!", "alert-success", true]
			redirect to "/tables/#{params[:table]}"
		end
	when 'roles'
			CRUD::Role.update(params[:id], defect: params[:Defect_T]? true : false,
												status: params[:Status_T]? true : false, maintenance: params[:Main_T]? true : false,
												pavilion: params[:Status_T]? true : false, post: params[:Post_T]? true : false)
			$message = ["Запись успешно изменена!", "alert-success", true]
			redirect to "/tables/#{params[:table]}"
	when 'statuses'
		@reload = {name: params[:Status_Name]}
		if CRUD::Status.find_by(name: @reload[:name])
			@message = ['alert-danger','Данный статус уже существует в базе!']
      erb :update
		else
			CRUD::Status.update(params[:id], name: params[:Status_Name])
			$message = ["Запись успешно изменена!", "alert-success", true]
			redirect to "/tables/#{params[:table]}"
		end
	when 'users'
    case
		when CRUD::User.find_by(phone: params[:User_Phone]) && CRUD::User.find(params[:id]).phone != params[:User_Phone]
			@message = ['alert-danger','Введенный вами номер телефона уже используется!']
      erb :update
		when	!((6..16).include? params[:User_Password].length)
			@message = ['alert-danger','Пароль должен содержать от 6 до 16 символов!']
      erb :update
		else
			CRUD::User.update(params[:id], password: params[:User_Password], role: params[:Role_Select].split[0].chomp('.'), name: params[:User_Name],
												surname: params[:User_Surname], patronymic: params[:User_Patronymic], phone: params[:User_Phone], post: params[:Post_Select].split[0].chomp('.'),
												pavilion: params[:Pavilion_Select].split[0].chomp('.'))
			$message = ["Запись успешно изменена!", "alert-success", true]
			redirect to "/tables/#{params[:table]}"
		end
	when 'maintenances'
		if params[:Date_Bid] == ''
			@message = ['alert-danger','Дата и время подачи заявки должны быть указаны!']
			erb :update
		elsif params[:Maintenance_Descr] == '' or params[:Maintenance_Descr].length > 255
			@message = ['alert-danger','Описание не должно быть пустым или превышать 255 символов!']
			erb :update
		else
			CRUD::Maintenance.update(params[:id], status: params[:Status_Select].split[0].chomp('.'), executor: params[:Executor_Select].split[0].chomp('.'),
															 client: params[:Client_Select].split[0].chomp('.'), bid_date: params[:Date_Bid], end_date: params[:Date_End],
															 defect: params[:Defect_Select].split[0].chomp('.'), description: params[:Maintenance_Descr])
			$message = ["Запись успешно изменена!", "alert-success", true]
			redirect to "/tables/#{params[:table]}"
		end
  end
  end
end

get '/tables/:table/:id/update' do
  if CRUD::Role.find(CRUD::User.find_by(login: session[:identity]).role).name == 'Администратор'
	  erb :update
  else
    erb :not_found
  end
end

get '/login' do
	if session[:identity]
		erb "<div class='alert alert-danger text-center'>Вы уже авторизованы!</div>"
	else
		erb :login
	end
end


post '/login' do
  case
  when params[:login] == '' || params[:pass] == ''
    @access = "Заполните поля"
    erb :login
  when CRUD::User.find_by(login: params[:login]) && params[:pass] == CRUD::User.find_by(login: params[:login]).password
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