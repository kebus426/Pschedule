# coding: utf-8
require 'sinatra/base'
require 'mysql2'
require 'date'
require 'bcrypt'

class Rooting < Sinatra::Base
  
  enable :sessions
  set :session_secret, "My session secret"
  
  get '/' do
    'Hello world!'
  end

  get '/p-schedule' do
    client = Mysql2::Client.new(host: "localhost",username: "root", password: "",database: "pschedule")
    @year = 0
    @month = 0
    begin
      @year = params['ey'] ? params['ey'].to_i : Time.now.year
      @month = params['em'] ? params['em'].to_i : Time.now.month
    rescue
      @year = Time.now.year
      @month = Time.now.month
    end
    @thisYear = Time.now.year
    targetMonthS = DateTime.new(@year,@month,1,0,0,0)
    targetMonthE = (targetMonthS >> 1)
    query = "SELECT * FROM event NATURAL JOIN time WHERE day >= \'#{rubyDateToSqlDate2(targetMonthS)}\' AND day < \'#{rubyDateToSqlDate2(targetMonthE)}\' ORDER BY day;"
    @events = client.query(query)
    @performance = client.query("SELECT *  FROM  performance")
    erb :index
  end

  get '/p-schedule/items/:id' do
    client = Mysql2::Client.new(host: "localhost",username: "root", password: "",database: "pschedule")
    query = client.prepare("SELECT * FROM event NATURAL JOIN performance NATURAL JOIN time WHERE id = ?")
    @data = query.execute(params[:id])
    @performance = client.query("SELECT *  FROM  performance")
    erb :items

  end

  get '/p-schedule/sign_up' do
    session[:user_id] ||= nil 
  if session[:user_id]
    redirect '/p-schedule/log_out' #logout form
  end 

  erb :sign_up
  end

  get '/p-schedule/log_out' do
  end 

  post '/p-schedule/user/new' do
    #if params[:password] != params[:confirm_password]
    #  redirect '/p-schedule/sign_up'
    #end

    begin
      client = Mysql2::Client.new(host: "localhost",username: "root", password: "",database: "pschedule")
      query = client.prepare"INSERT INTO user (name, password, password_salt) VALUES(?,?,?)"
      password_info = encrypt_password(params[:password])
      query.execute(params[:name], password_info["password"],password_info["password_salt"])
      params[:user_id] = client.prepare("SELECT id FROM user WHERE name = ?").execute(params[:name])
      redirect '/p-schedule'
    #rescue => ex 
    #  puts ex
    #  redirect '/p-schedule/sign_up'
    end
  
  end
  
  def authenticate(name, password)
    client = Mysql2::Client.new(host: "localhost",username: "root", password: "",database: "pschedule")
    query = client.prepare("SELECT * FROM user WHERE name = ?")
    user = query.execute(name)
    if user && user["password"] == BCrypt::Engine.hash_secret(password, user["password_salt"])
      user
    else
      nil 
    end 
  end 

  def encrypt_password(password)
    if password
      ret = {}
      ret["password_salt"] = BCrypt::Engine.generate_salt
      ret["password"] = BCrypt::Engine.hash_secret(password, ret["password_salt"])
      return ret
    end 
  end 

  def rubyDateToSqlDate(year,month,day,hour,minute,second)
    return "#{year}-#{format('%.2d',month)}-#{format('%.2d',day)} #{format('%.2d',hour)}:#{format('%.2d',minute)}:#{format('%.2d',second)}"
  end

  def rubyDateToSqlDate2(dt)
    return "#{dt.year}-#{format('%.2d',dt.month)}-#{format('%.2d',dt.day)} #{format('%.2d',dt.hour)}:#{format('%.2d',dt.minute)}:#{format('%.2d',dt.second)}"
  end

end
