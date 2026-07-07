ENV["RAILS_ENV"] ||= "test"
require "simplecov"
SimpleCov.start
require_relative "../config/environment"
require "rails/test_help"
require "minitest/reporters"
Minitest::Reporters.use! # Minitest::Reporters::SpecReporter.new

require "webmock/minitest"
# テストから実ネットワークへのアクセスを禁止する（外部 API はスタブ必須にする）。
# localhost は Capybara/Selenium がブラウザと通信するために許可が必要
WebMock.disable_net_connect!(allow_localhost: true)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
