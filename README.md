# Pschedule
プロデューサースケジュール管理

## how to use
```
#bash
bundle install --path vendor/bundle 
#bundle installできない場合、下のを適宜インストールしてから再度試す
#ここから
sudo apt-get install ruby-dev
sudo apt-get install libmysqlclient-dev
sudo apt-get install build-essential
#ここまで
npm install
npm run build
mysql -u root -p < initDB.sql
bundle exec ruby scrape.rb init
```
```
#pschedule.conf
# use the socket we configured in our unicorn.rb
	upstream unicorn_server {
      #ここのパスは書き換える
	  server unix:/your/pass/Pschedule/tmp/sockets/unicorn.sock;
 	}

server{
	# replace with your domain name
   	server_name pschedule;
   	# replace this with your static Sinatra app files, root + public
  	root /home/kebus/Pschedule/public;
   	# port to listen for requests on
   	listen 80;
   	# maximum accepted body size of client request
   	client_max_body_size 4G;
   	# the server will close connections after this time
   	keepalive_timeout 5;
    location / {
 	   try_files $uri @app;
    }

    location @app {
        # pass to the upstream unicorn server mentioned above
      	proxy_pass http://unicorn_server;
	}	
}
```
```
#bash
bundle exec unicorn -c unicorn.rb -E production -D
```