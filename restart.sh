cat tmp/pids/unicorn.pid | xargs kill -QUIT
bundle exec unicorn -c unicorn.rb -E production -D
