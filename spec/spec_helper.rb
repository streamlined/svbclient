# Encoding: utf-8
# adapted from Leaflet-Rails

require 'simplecov'
require 'simplecov-rcov'

SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
SimpleCov.start

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

ENV['RAILS_ENV'] ||= 'test'

require 'action_controller/railtie'
require 'rails/test_unit/railtie'
require 'leaflet-rails'

module Test
  class Application < ::Rails::Application
    config.active_support.deprecation = :stderr
  end
end

Test::Application.initialize!

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end