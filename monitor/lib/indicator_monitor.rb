class IndicatorMonitor
  def initialize(poster = Poster.new)
    @poster = poster
  end

  def active?(uri)
    numbers = poster.numbers
    result = JSON.parse(poster.post("#{uri}/jsonrpc", JSON.dump(
      jsonrpc: "2.0",
      method: "add",
      id: poster.id,
      params: numbers
    )))
    result["result"] == numbers.sum
  rescue
    false
  end

  private

  attr_reader :poster
end

require "faraday"
require "securerandom"

Faraday.default_adapter = :net_http

class Poster
  def post(uri, data)
    connection = Faraday.new(host(uri), request: {timeout: 1})
    connection.post(path(uri), data).body
  end

  def numbers
    [SecureRandom.random_number(1000), SecureRandom.random_number(1000)]
  end

  def id
    SecureRandom.base64(21)
  end

  private

  # host("http://localhost:4567/api") => "http://localhost:4567"
  def host(uri)
    uri[/^.+(?=\/)/]
  end

  # path("http://localhost:4567/api") => "/api"
  def path(uri)
    uri[/\/[^\/]+$/]
  end
end
