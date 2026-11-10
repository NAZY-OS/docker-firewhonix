#!/bin/bash

# Base port for Tor instances (SOCKS proxies)
TOR_PORT_BASE=9061
MAX_INSTANCES=12
BASE_TMP_DIR="/mnt/ramdisk"

# Load the SOCKS ports from the temporary file
read -r PORTS < /tmp/tor_ports
FORMATTED_LOCALHOSTPORTS=$(echo "$PORTS" | sed 's/ /,/g')

start_tor_clients() {
  mount -t tmpfs -o size=1G tmpfs "$BASE_TMP_DIR" 2> /dev/null
  PORTS=""

  for I in $(seq 1 "$MAX_INSTANCES"); do
    PORT=$((TOR_PORT_BASE + I - 1))
    if [ -z "$PORTS" ]; then
      PORTS="127.0.0.1:$PORT"
    else
      PORTS="$PORTS,127.0.0.1:$PORT"
    fi

    TOR_DATA_DIR="$BASE_TMP_DIR/tor_instance_$PORT"
    mkdir -p "$TOR_DATA_DIR"
    chown tor:tor "$TOR_DATA_DIR"

    sudo tor \
      --User tor \
      --SocksPort "$PORT" \
      --ControlPort "$((PORT + 100))" \
      --DataDirectory "$TOR_DATA_DIR" \
      --Sandbox 1 \
      --HardwareAccel 1 \
      --BandwidthRate 400000 \
      --BandwidthBurst 400000 \
      --ExcludeExitNodes {us},{uk},{ca},{au},{nz},{dk},{fr},{nl},{no},{de},{be},{it},{es},{se},{sg},{il},{kr},{ru},{by},{am},{cn},{ir},{kp},{kz},{kg},{tj},{sy} \
      --ClientOnly 1 \
      --DisableNetwork 0 \
      --UseBridges 0 \
      --StrictNodes 1 \
      --MaxClientCircuitsPending 200 \
      --EnforceDistinctSubnets 0 \
      --CircuitStreamTimeout 300 \
      --KeepalivePeriod 60 \
      --CircuitBuildTimeout 30 \
      --LearnCircuitBuildTimeout 0 \
      --MaxCircuitDirtiness 600 \
      --CircuitStreamTimeout 600 \
      --UseEntryGuards 1 \
      --NumEntryGuards 6 \
      --DisableDebuggerAttachment 1 \
      --AvoidDiskWrites 1 &

    echo "Started Tor client on SOCKS port $PORT (ControlPort=$((PORT+100)))"
    sleep 1
  done

  echo "${PORTS//,/ }" > /tmp/tor_ports
}

renew_circuits() {
  while true; do
    COUNT=$(pidof tor | wc -w)
    if [ "$COUNT" -ge 10 ]; then
      echo "Renewing circuits for $COUNT Tor instances..."
      for PID in $(pidof tor); do
        kill -USR1 "$PID"
        echo "  - Renewed circuit for PID $PID"
      done
    fi
    sleep $((RANDOM % 301 + 300))
  done &
}

running_init_since() {
  echo
  echo "==============================================="
  echo "Firewhonix Loadbalancer gestartet!"
  echo "==============================================="
  echo

  START_TEXT=$(date '+%Y-%m-%d %H:%M:%S')
  echo "Betriebszeit: $START_TEXT"
  echo

  (
    while true; do
      sleep 15
      PID_COUNT=$(pidof tor 2>/dev/null | wc -w)
      ACTIVE_PIDS=$(pidof tor 2>/dev/null)

      echo "==============================================="
      echo "Firewhonix Status:"
      echo "-----------------------------------------------"
      echo "Aktive Tor-Prozesse (PIDs): $PID_COUNT"
      echo "Verwendete Ports: $FORMATTED_LOCALHOSTPORTS"
      echo "go-dispatch-proxy Parameter:"
      echo "  -lhost 127.0.0.1"
      echo "  -lport 4711"
      echo "  -tunnel"
      echo "  $FORMATTED_LOCALHOSTPORTS"
      echo "-----------------------------------------------"
      echo "Aktive PIDs: $ACTIVE_PIDS"
      echo "==============================================="
    done
  ) &
}

start_dispatch_proxy() {
  PPORT=4711

  echo "Starte go-dispatch-proxy mit folgenden Parametern:"
  echo "  /usr/bin/go-dispatch-proxy -lhost 127.0.0.1 -lport $PPORT -tunnel $FORMATTED_LOCALHOSTPORTS"
  echo

  while true; do
    if [ -n "$PROXY_PID" ]; then
      kill "$PROXY_PID" 2>/dev/null
      wait "$PROXY_PID" 2>/dev/null
    fi

    /usr/bin/go-dispatch-proxy \
      -lhost 127.0.0.1 \
      -lport "$PPORT" \
      -tunnel \
      "$FORMATTED_LOCALHOSTPORTS" &
    PROXY_PID=$!

    sleep 45
  done &
}

# Main execution
start_tor_clients
running_init_since
sleep 20
renew_circuits
start_dispatch_proxy

wait
