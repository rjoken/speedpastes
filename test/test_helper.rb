ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

class ActionDispatch::IntegrationTest
  def sign_in_as(user, password: "password")
    post login_path, params: { email: user.email, password: password }
  end

  def api_headers(user, *scopes)
    _, raw_token = ApiToken.generate!(user: user, name: "test", scopes: scopes, expires_in: nil)
    { "Authorization" => "Bearer #{raw_token}" }
  end

  def json_headers(headers)
    headers.merge("Content-Type" => "application/json")
  end

  def with_memory_cache
    original = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    yield
  ensure
    Rails.cache = original
  end
end
