require 'sinatra/base'
require 'mysql2'

class Rooting < Sinatra::Base

  get '/' do
    'Hello world!'
  end

  get '/p-schedule' do
    client = Mysql2::Client.new(host: "localhost",username: "root", password: "",database: "pschedule")
    query = "select * from event;"
    @data = client.query(query)
    erb :index
  end

end
