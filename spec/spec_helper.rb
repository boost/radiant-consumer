ENV["RAILS_ENV"] ||= "test"

unless defined? RAILS
  require 'rubygems'
end

unless defined? RAILS_ENV
  RAILS_ENV = ENV["RAILS_ENV"]
end

require 'spec'
require 'action_controller'
require 'action_controller/caching'