require "json"
require "indicator_monitor"

class PosterMock
  attr_reader :id, :numbers, :request_uri, :request_data
  def initialize(id, numbers, result)
    @id = id
    @numbers = numbers
    @result = {
      jsonrpc: "2.0",
      id: id
    }.merge(result)
  end

  def post(uri, data)
    @request_uri = uri
    @request_data = JSON.parse(data)
    JSON.dump(@result)
  end
end

class PosterWithTimeout < PosterMock
  def post(uri, data)
    raise StandardError.new("Timeout")
  end
end

RSpec.describe IndicatorMonitor do
  let(:monitor) { IndicatorMonitor.new(poster) }

  context "adding 1 + 1 to get 2" do
    let(:poster) { PosterMock.new(0, [1, 1], result: 2) }

    it "sends an appropriate request and returns true" do
      expect(monitor.active?("http://something:1234")).to be true
      expect(poster.request_uri).to eq "http://something:1234/jsonrpc"
      expect(poster.request_data["jsonrpc"]).to eq "2.0"
      expect(poster.request_data["id"]).to eq 0
      expect(poster.request_data["method"]).to eq "add"
      expect(poster.request_data["params"]).to eq [1, 1]
    end
  end

  context "adding 2 + 2 to get 4" do
    let(:poster) { PosterMock.new(1, [2, 2], result: 4) }

    it "sends an appropriate request and returns true" do
      expect(monitor.active?("http://something:2468")).to be true
      expect(poster.request_uri).to eq "http://something:2468/jsonrpc"
      expect(poster.request_data["jsonrpc"]).to eq "2.0"
      expect(poster.request_data["id"]).to eq 1
      expect(poster.request_data["method"]).to eq "add"
      expect(poster.request_data["params"]).to eq [2, 2]
    end
  end

  context "adding 2 + 2 to get 5" do
    let(:poster) { PosterMock.new("abc", [2, 2], result: 5) }

    it "sends an appropriate request and returns false" do
      expect(monitor.active?("http://xyz:8080")).to be false
      expect(poster.request_uri).to eq "http://xyz:8080/jsonrpc"
      expect(poster.request_data["jsonrpc"]).to eq "2.0"
      expect(poster.request_data["id"]).to eq "abc"
      expect(poster.request_data["method"]).to eq "add"
      expect(poster.request_data["params"]).to eq [2, 2]
    end
  end

  context "timing out" do
    let(:poster) { PosterWithTimeout.new("abc", [2, 2], result: 5) }

    it "returns false" do
      expect(monitor.active?("http://xyz:8080")).to be false
    end
  end
end
