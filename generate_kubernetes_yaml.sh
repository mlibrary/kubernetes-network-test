#!/usr/bin/env bash
PROG="$0"
USAGE="WORKER_1 [WORKER_2...]"

errorout() {
  echo "usage: ${PROG} -h" >&2
  echo "  or   ${PROG} ${USAGE}" >&2
  [ -n "$1" ] && echo "${PROG}: error: $@" >&2
  exit 1
}

printhelp() {
  cat <<EOF
usage: ${PROG} ${USAGE}

This generates some yaml that you can put in a file and apply to run in
a kubernetes cluster. For example:

    $PROG worker-{30..37}.macc.test

That will generate the yaml to create 16 new deployments and 16 new
services on 8 worker nodes, each configured to connect to each other
node.

positional arguments:
 WORKER...  a complete list of worker nodes

optional arguments:
 -h         print this help text and exit
EOF
}

while getopts ':hn:' opt; do
  case "$opt" in
    h)
      printhelp
      exit 0
      ;;

    ?)
      errorout "unrecognized argument: \`-$opt'"
      ;;
  esac
done
shift $((OPTIND - 1))

main() {
  INDICATORS=`join_with_comma "$@"`
  for node in "$@"; do
    print_kubernetes "$node"
  done
}

join_with_comma() {
  echo -n "http://network-indicator-${1//./-}:4567"
  shift
  for i in "$@"; do
    echo -n ",http://network-indicator-${i//./-}:4567"
  done
}

print_kubernetes() {
  cat <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: network-indicator-${1//./-}
spec:
  selector:
    matchLabels:
      app: network-indicator
      node: $1
  template:
    metadata:
      labels:
        app: network-indicator
        node: $1
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchFields:
              - key: metadata.name
                operator: In
                values:
                - $1
      containers:
      - name: indicator
        image: ghcr.io/mlibrary/kubernetes-network-test-indicator:1.0.0
        env:
        - name: RACK_ENV
          value: production
        ports:
        - name: http
          containerPort: 4567
        livenessProbe:
          httpGet:
            path: /-/liveness
            port: 4567
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: network-monitor-${1//./-}
spec:
  selector:
    matchLabels:
      app: network-monitor
      node: $1
  template:
    metadata:
      labels:
        app: network-monitor
        node: $1
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchFields:
              - key: metadata.name
                operator: In
                values:
                - $1
      containers:
      - name: monitor
        image: ghcr.io/mlibrary/kubernetes-network-test-monitor:1.0.0
        env:
        - name: RACK_ENV
          value: production
        - name: INDICATORS
          value: $INDICATORS
        ports:
        - name: http
          containerPort: 4568
        livenessProbe:
          httpGet:
            path: /-/liveness
            port: 4568
---
apiVersion: v1
kind: Service
metadata:
  name: network-indicator-${1//./-}
spec:
  selector:
    app: network-indicator
    node: $1
  ports:
  - name: http
    port: 4567
---
apiVersion: v1
kind: Service
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "4568"
    prometheus.io/path: "/metrics"
  name: network-monitor-${1//./-}
spec:
  selector:
    app: network-monitor
    node: $1
  ports:
  - name: http
    port: 4568
EOF
}

main "$@"
