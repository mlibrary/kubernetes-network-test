ENV["APP_ENV"] = "test"

require_relative "indicator_app"
require "json"
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

  it "can add 1, 2, and 3 to get 6" do
    post("/jsonrpc", JSON.dump(
      jsonrpc: "2.0",
      id: 123,
      method: "add",
      params: [1, 2, 3]
    ))

    expect(last_response).to be_ok
    expect(JSON.parse(last_response.body)).to eq(
      "jsonrpc" => "2.0",
      "id" => 123,
      "result" => 6
    )
  end

  it "can add 10 and 11 to get 21" do
    post("/jsonrpc", JSON.dump(
      jsonrpc: "2.0",
      id: 456,
      method: "add",
      params: [10, 11]
    ))

    expect(last_response).to be_ok
    expect(JSON.parse(last_response.body)).to eq(
      "jsonrpc" => "2.0",
      "id" => 456,
      "result" => 21
    )
  end
end
