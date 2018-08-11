require 'sinatra/base'

class Rooting < Sinatra::Base

  get '/' do
    'Hello world!'
  end

  get '/p-schedule' do
    erb :index
  end


end
