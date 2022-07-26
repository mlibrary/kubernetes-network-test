require "sinatra"
require_relative "lib/indicator_monitor"

get "/metrics" do
  metric = "kube_end_to_end_network_indicator_up"
  help_comment = <<~HELP
    # HELP #{metric} 1 if this monitor can talk to a given indicator, 0 if not.
    # TYPE #{metric} gauge
  HELP

  metric_line = lambda { |i| "#{metric}{indicator=\"#{i}\"} #{IndicatorMonitor.new.active?(i) ? 1 : 0}\n" }
  help_comment + ENV["INDICATORS"].split(",").map { |i| metric_line.call(i) }.join("")
end

get "/-/liveness" do
  ""
end
