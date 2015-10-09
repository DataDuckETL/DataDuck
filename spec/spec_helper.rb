require 'bundler/setup'
Bundler.setup

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'dataduck'

RSpec.configure do |config|
  # some (optional) config here
end
