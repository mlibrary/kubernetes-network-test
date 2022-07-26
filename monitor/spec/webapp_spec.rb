ENV["APP_ENV"] = "test"

require_relative "../monitor_app"
require "rspec"
require "rack/test"

RSpec.describe "The indicator app" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  it "responds ok to a liveness check" do
    get("/-/liveness")
    expect(last_response).to be_ok
  end
end
