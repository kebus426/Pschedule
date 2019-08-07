# coding: utf-8
require 'sinatra/base'
require 'mysql2'
require 'date'
require 'bcrypt'
require 'sinatra/namespace'

class Rooting < Sinatra::Base
  register Sinatra::Namespace
  
  enable :sessions
  set :session_secret, "My session secret"
  
  namespace '/p-schedule' do
    get '' do
      client =  MakeClient()
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
  
    get '/items/:id' do
      client =  MakeClient()
      query = client.prepare("SELECT * FROM event NATURAL JOIN performance NATURAL JOIN time WHERE id = ?")
      @data = query.execute(params[:id])
      @performance = client.query("SELECT *  FROM  performance")
      erb :items
  
    end 
  
    get '/sign_up' do
      session[:user_id] ||= nil 
      if session[:user_id]
        redirect '/p-schedule/log_out' #logout form
      end 
      
      erb :sign_up
    end
  
    get '/sign_in' do
      session[:user_id] ||= nil 
      if session[:user_id]
        redirect '/p-schedule' #logout form
      end 
      erb :sign_in
    end
  
    post '/sign_in' do
      user = authenticate(params[:name],params[:password])
      if(user != nil)      
        session[:user_id] = user["id"]
        redirect 'p-schedule'
      else
        redirect 'p-schedule/sign_in'
      end
    end
  
    get '/log_out' do
    end 
  
    #user登録
    post '/user/new' do
      #if params[:password] != params[:confirm_password]
      #  redirect '/p-schedule/sign_up'
      #end
  
      begin
        client =  MakeClient()
        query = client.prepare("INSERT INTO user (name, password, password_salt) VALUES(?,?,?)")
        password_info = encrypt_password(params[:password])
        query.execute(params[:name], password_info["password"],password_info["password_salt"])
        
        client.prepare("SELECT id FROM user WHERE name = ?").execute(params[:name]).each do |id|
          session[:user_id] = id
        end
        redirect '/p-schedule'
      rescue => ex 
        puts ex
        redirect '/p-schedule/sign_up'
      end
    
    end

    #userページ
    get 'mypage' do
      client = MakeClient()
      result = client.prepare("SELECT * FROM user WHERE id = ?").execute(session[:user_id])
      if(result)
        @user = user.first
        user_bought_result = client.query("SELECT * FROM user_bought WHERE user_id = #{@user.id}")
        @user_bought = user_bought_result ? user_bought_result.first : nil
        erb :mypage
      else
        redirect '/p-schedule/sign_up'
      end
      
    end

  end
  


#関数
  
  def authenticate(name, password)
    client = MakeClient()
    query = client.prepare("SELECT * FROM user WHERE name = ?")
    user = query.execute(name)
    #userは配列か何かなので取り出す必要がありそう
    if user
      #userはnameに制約つけてた気がする
      user.each do |u|
        if u["password"] == BCrypt::Engine.hash_secret(password, u["password_salt"])
          return u
        end
      end
      #複数あったときのために外に出しておく
      return nil     
    else
      return nil 
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

  def MakeClient()
    File.open('dbPass.txt') do |f|
      return Mysql2::Client.new(host: "localhost",username: "root", password: f.read,database: "pschedule")
    end
  end
end