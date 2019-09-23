require "rubygems"
require "sinatra"

require File.expand_path '../sinatra.rb', __FILE__

Encoding.default_external = Encoding::UTF_8
run Rooting
