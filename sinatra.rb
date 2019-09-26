# coding: utf-8
require 'sinatra/base'
require 'mysql2'
require 'date'
require 'bcrypt'
require 'sinatra/namespace'
require 'mysql2-cs-bind'

class Rooting < Sinatra::Base
  register Sinatra::Namespace
  
  enable :sessions
  set :session_secret, "My session secret"
  
  namespace '/p-schedule' do
    get '' do
      client =  MakeClient()
      @year = 0
      @month = 0
      @spanFlag = (params.has_key?('start_year') && params['start_year'] != '') || (params.has_key?('end_year') && params['end_year'] != '')
      if @spanFlag
        if params.has_key?('start_year') && params['start_year'] != ''
          monthS = params.has_key?('start_month') && params['start_month'] != '' ? params['start_month'].to_i : 1
          @spanStart = DateTime.new(params['start_year'].to_i,monthS,1,0,0,0)
        else 
          @spanStart = DateTime.new(2016,1,1,0,0,0,0)
        end

        if params.has_key?('end_year') && params['end_year'] != ''
          monthE = params.has_key?('end_month') && params['end_month'] != '' ? params['end_month'].to_i : 1
          @spanEnd = (DateTime.new(params['end_year'].to_i,monthE,1,0,0,0) >> 1)
        else 
          @spanEnd = (DateTime.now >> 1)
        end
      else
        @year = params.has_key?('ey') ? params['ey'].to_i : Time.now.year
        @month = params.has_key?('em') ? params['em'].to_i : Time.now.month
        @spanStart = DateTime.new(@year,@month,1,0,0,0)
        @spanEnd = (@spanStart >> 1)
      end
      
      genres = ["CD","webラジオ","web配信","雑誌","単行本","イベント","ニコ生"]
      @genre_filter = []
      genres.each do |genre|
        if params[genre] == "on"
            @genre_filter.push(genre)
        end
      end

      @search_event_name = params.has_key?('search_event_name') && params['search_event_name'] != '' ? params['search_event_name'] : ''

      performances = ["765","シンデレラ","ミリオン","SideM","シャイニー"]
      @performance_filter = []
      performances.each do |performance|
        if params[performance] == "on"
            @performance_filter.push(performance)
        end
      end
      
      if session[:user_id]
          query = %{
            SELECT 
            event.*,
            time.day,
            time.special,
            favorite.user_id AS favorite_user_id,
            favorite.event_id AS favorite_event_id,
            bought.event_id AS bought_event_id,
            bought.user_id AS bought_user_id
            FROM
                time 
            NATURAL JOIN event  
            LEFT JOIN user_favorite AS favorite
            ON 
              event.id = favorite.event_id
              AND 
              favorite.user_id = ? 
            LEFT JOIN user_bought AS bought
            ON 
              event.id = bought.event_id
              AND 
              bought.user_id = ?
            WHERE 
              day >= ? 
              AND 
              day < ? 
          }
          query = query << "AND genre IN (?) " if @genre_filter.count > 0
          query = query << "AND name like ?" if @search_event_name != ''
          query = query << "ORDER BY day;"
          if @genre_filter.count == 0 && @search_event_name == ''
            @events = client.xquery(query,session[:user_id],session[:user_id],rubyDateToSqlDate2(@spanStart),rubyDateToSqlDate2(@spanEnd))
          elsif @search_event_name == ''
            @events = client.xquery(query,session[:user_id],session[:user_id],rubyDateToSqlDate2(@spanStart),rubyDateToSqlDate2(@spanEnd),@genre_filter)
          elsif @genre_filter.count == 0
            @events = client.xquery(query,session[:user_id],session[:user_id],rubyDateToSqlDate2(@spanStart),rubyDateToSqlDate2(@spanEnd), '%' << @search_event_name << '%')
          else
            @events = client.xquery(query,session[:user_id],session[:user_id],rubyDateToSqlDate2(@spanStart),rubyDateToSqlDate2(@spanEnd),@genre_filter, '%' << @search_event_name << '%')
          end
      else
        if @genre_filter.count == 0
          query = client.prepare("SELECT * FROM event NATURAL JOIN time WHERE day >= ? AND day < ? ORDER BY day;")
          @events = query.execute(rubyDateToSqlDate2(@spanStart),rubyDateToSqlDate2(@spanEnd))
        else
          query = "SELECT * FROM event NATURAL JOIN time WHERE day >= ? AND day < ? AND genre IN (?) ORDER BY day;"
          @events = client.xquery(query,rubyDateToSqlDate2(@spanStart),rubyDateToSqlDate2(@spanEnd),@genre_filter)
        end
      end
      
      query = "SELECT *  FROM  performance"
      @performance = client.xquery(query)
      erb :index
    end
  
    get '/items/:id' do
      client =  MakeClient()
      query = %{
        SELECT 
          event.*,
          performance.*,
          time.*, 
          favorite.user_id AS favorite_user_id,
          favorite.event_id AS favorite_event_id,
          bought.event_id AS bought_event_id,
          bought.user_id AS bought_user_id
        FROM 
          event
          NATURAL JOIN 
          performance
          NATURAL JOIN 
          time 
          LEFT JOIN user_favorite AS favorite
          ON 
            event.id = favorite.event_id
            AND 
            favorite.user_id = ? 
          LEFT JOIN user_bought AS bought
          ON 
            event.id = bought.event_id
            AND 
            bought.user_id = ?
        WHERE 
          event.id = ?
        ORDER BY day DESC
        LIMIT 10
      }
      @user_id = session[:user_id] ? session[:user_id] : -1
      @data = client.xquery(query,@user_id,@user_id,params[:id])
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
      session[:user_id] = nil
      redirect 'p-schedule'
    end 
  
    #user登録
    post '/user/new' do
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
    get '/mypage' do
      client = MakeClient()
      result = client.prepare("SELECT name, id FROM user WHERE id = ?").execute(session[:user_id])
      if(result)
        user = result.first
        @username = user["name"]
        query = %{
          SELECT 
            event.*,
            favorite.user_id AS favorite_user_id, 
            bought.user_id AS bought_user_id
          FROM 
            event 
            LEFT JOIN user_favorite AS favorite 
              ON event.id=favorite.event_id 
              AND favorite.user_id=?
            LEFT JOIN user_bought AS bought 
              ON event.id=bought.event_id 
              AND bought.user_id=?
        }
        user_data = client.xquery(query,user["id"],user["id"])
        @user_favorite = user_data.select{|elm| elm['favorite_user_id'] != nil}
        @user_bought = user_data.select{|elm| elm['bought_user_id'] != nil}
  
        query = "SELECT *  FROM  performance"
        @performance = client.xquery(query)
        
        erb :mypage
        
      else
        redirect '/p-schedule/sign_up'
      end
    end

    post '/favorite/new' do
      id = request.body.read.delete("eventid=")
      client = MakeClient()
      result = client.prepare("SELECT * FROM event WHERE id = ?").execute(id)
      item = result ? result.first : nil
      favorite_result = client.prepare("SELECT * FROM user_favorite WHERE user_id = ? AND event_id = ?").execute(session[:user_id],id)
      if(item && session[:user_id]  && favorite_result.count == 0)
        client.prepare("INSERT INTO user_favorite (user_id,event_id) VALUES(?,?)").execute(session[:user_id],id)
        @data = "success"
      else 
        @data = "failed"       
      end
    end

    post '/favorite/delete' do
      id = request.body.read.delete("eventid=")
      client = MakeClient()
      if(session[:user_id])
        result = client.prepare("SELECT * FROM user_favorite WHERE id = ? AND user_id = ?").execute(id,session[id])
        if(result)
          client.prepare("DELETE FROM user_favorite WHERE user_id = ? AND event_id = ?").execute(session[:user_id],id)
          @data = "success"
        else 
          @data="failed"
        end
      end
    end

    post '/bought/new' do
      id = request.body.read.delete("eventid=")
      client = MakeClient()
      result = client.prepare("SELECT * FROM event WHERE id = ?").execute(id)
      item = result ? result.first : nil
      bought_result = client.prepare("SELECT * FROM user_bought WHERE user_id = ? AND event_id = ?").execute(session[:user_id],id)
      if(item && session[:user_id]  && bought_result.count == 0)
        client.prepare("INSERT INTO user_bought (user_id,event_id) VALUES(?,?)").execute(session[:user_id],id)
        @data = "success"
      else 
        @data = "failed"       
      end
    end

    post '/bought/delete' do
      id = request.body.read.delete("eventid=")
      client = MakeClient()
      if(session[:user_id])
        result = client.prepare("SELECT * FROM user_bought WHERE id = ? AND user_id = ?").execute(id,session[id])
        if(result)
          client.prepare("DELETE FROM user_bought WHERE user_id = ? AND event_id = ?").execute(session[:user_id],id)
          @data = "success"
        else 
          @data="failed"
        end
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
