$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'finker'
require 'fakefs/spec_helpers'

RSpec.configure do |config|
  config.include FakeFS::SpecHelpers
end

