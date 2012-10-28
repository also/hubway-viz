# This file can be symlinked into a directory

local_dir = File.dirname __FILE__
Dir.chdir File.dirname File.readlink(__FILE__)

require "rubygems"
require "bundler/setup"

Bundler.require(:default)

require 'sinatra'

configure do
  set :local_dir, local_dir
end

require './app'

run Sinatra::Application
