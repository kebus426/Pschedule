# coding: utf-8
require 'sinatra/base'
require 'mysql2'
require 'date'

class Rooting < Sinatra::Base
  
  get '/' do
    'Hello world!'
  end

  get '/p-schedule' do
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
    client = Mysql2::Client.new(host: "localhost",username: "root", password: "",database: "pschedule")
    query = "SELECT * FROM event NATURAL JOIN performance NATURAL JOIN time WHERE day >= \'#{rubyDateToSqlDate2(targetMonthS)}\' AND day < \'#{rubyDateToSqlDate2(targetMonthE)}\' ORDER BY day;"
    @data = client.query(query)
    erb :index
  end


  def rubyDateToSqlDate(year,month,day,hour,minute,second)
    return "#{year}-#{format('%.2d',month)}-#{format('%.2d',day)} #{format('%.2d',hour)}:#{format('%.2d',minute)}:#{format('%.2d',second)}"
  end

  def rubyDateToSqlDate2(dt)
    return "#{dt.year}-#{format('%.2d',dt.month)}-#{format('%.2d',dt.day)} #{format('%.2d',dt.hour)}:#{format('%.2d',dt.minute)}:#{format('%.2d',dt.second)}"
  end

end
