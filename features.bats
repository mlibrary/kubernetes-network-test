#!/usr/bin/env bats

# Given a healthy kubernetes network
# When viewing a monitor instance
# Then the monitor should report that the network is healthy
@test "with a healthy network, the monitor can talk to indicators" {
  podman build --tag indicator --file indicator/Containerfile.serve indicator
  podman build --tag monitor --file monitor/Containerfile.serve monitor
  indicator=`podman create --network host indicator`
  monitor=`podman create --network host --env INDICATORS=http://localhost:4567 monitor`
  podman start $indicator
  podman start $monitor

  for i in http://localhost:{4567,4568}/-/liveness; do
    while ! curl "$i"; do
      sleep 1
    done
  done

  body=`curl http://localhost:4568/metrics`

  podman stop $indicator
  podman stop $monitor
  podman rm $indicator
  podman rm $monitor

  echo "$body" >&2
  echo "$body" | grep '^kube.*{indicator="http://localhost:4567"} 1$'
}

# Given an indicator is unreachable
# When viewing a monitor instance
# Then the monitor should report that it cannot reach the indicator
@test "when an indicator is unreachable, the monitor reports it unreachable" {
  podman build --tag monitor --file monitor/Containerfile.serve monitor
  monitor=`podman create --network host --env INDICATORS=http://localhost:4567 monitor`
  podman start $monitor

  while ! curl http://localhost:4568/-/liveness; do
    sleep 1
  done

  body=`curl http://localhost:4568/metrics`

  podman stop $monitor
  podman rm $monitor

  echo "$body" >&2
  echo "$body" | grep '^kube.*{indicator="http://localhost:4567"} 0$'
}
