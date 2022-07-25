require "json"
require "sinatra"

post "/jsonrpc" do
  o = JSON.parse(request.body.read)
  JSON.dump(
    jsonrpc: "2.0",
    id: o["id"],
    result: o["params"].sum
  )
end
