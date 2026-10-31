#!/bin/bash

# Base port for Tor instances (SOCKS proxies)
TOR_PORT_BASE=9061  # Adjust to the port range used by your Docker/script setup

# Maximum number of Tor instances
MAX_INSTANCES=12

# Temporary directory for Tor instances
BASE_TMP_DIR="/mnt/ramdisk"  # Ensure this path exists or is mountable

start_tor_clients() {
  # Mount tmpfs to keep Tor data in memory (best performance)
  mount -t tmpfs -o size=1G tmpfs "$BASE_TMP_DIR" 2> /dev/null

  # Track ports
  PORTS=""

  for I in $(seq 1 "$MAX_INSTANCES"); do
    # Compute the SOCKS port for this instance
    PORT=$((TOR_PORT_BASE + I - 1))

    # Save SOCKS port
    if [ -z "$PORTS" ]; then
      PORTS="$PORT"
    else
      PORTS="$PORTS,$PORT"
    fi

    # Create a unique folder for each Tor instance
    TOR_DATA_DIR="$BASE_TMP_DIR/tor_instance_$PORT"
    mkdir -p "$TOR_DATA_DIR"

    # Set ownership so the tor user can write its data directory
    chown tor:tor "$TOR_DATA_DIR"

    # Start Tor instance with all parameters
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

    # Log started instance
    echo "Started Tor client on SOCKS port $PORT with data directory $TOR_DATA_DIR (ControlPort=$((PORT+100)))"

    # Give Tor a moment to start
    sleep 1
  done

  # Save the SOCKS ports in a temporary file
  echo "${PORTS//,/ }" > /tmp/tor_ports
}

# Signal processing loop to renew circuits
renew_circuits() {
  while true; do
    # Count number of Tor processes
    COUNT=$(pidof tor | wc -w)

    # If at least 10 Tor instances are running, renew circuits
    if [ "$COUNT" -ge 10 ]; then
      echo "There are at least 10 instances of Tor running."
      sleep 10
      for PID in $(pidof tor); do
        # Send USR1 to trigger circuit renewal
        kill -USR1 "$PID"
        echo "Renewing circuit for PID $PID"
      done
    else
      # If fewer than threshold Tor instances are running, wait
      sleep 10
      continue
    fi

    # Random delay between 300 and 600 seconds
    sleep $((RANDOM % 301 + 300))
  done &
}

running_init_since() {
  echo
  echo "_______________________________________________"
  echo "Starting go-dispatcher for Loadbalancing Tor!"
  echo "_______________________________________________"
  echo

  START_TEXT=$(date '+%Y-%m-%d.%H:%M:%S')
  echo "Firewhonix Loadbalancer is running since $START_TEXT"

  (
    while true; do
      sleep 15
      PID_COUNT=$(pidof tor 2>/dev/null | wc -w)
      echo "Firewhonix is running with $PID_COUNT PIDs"
    done
  ) &
}

start_dispatch_proxy() {
  while true; do
    FORMATTED_LOCALHOSTPORTS=$(
      sudo lsof -nP -a -c tor -iTCP -sTCP:LISTEN 2>/dev/null |
        sed -n 's/.*\(127[^ ]*\) (LISTEN).*/\1/p' |
        sort -u |
        paste -sd' ' -
    )

    if [ -z "$FORMATTED_LOCALHOSTPORTS" ]; then
      echo "ERROR: No Tor listening ports found. Check if Tor instances are running."
      echo
      echo "Possible causes:"
      echo "1. Tor processes crashed"
      echo "2. Port conflicts"
      echo "3. Permission issues"
      echo "4. Insufficient system resources"
      echo
    else
      echo "Balancing to these ports: $FORMATTED_LOCALHOSTPORTS"

      if [ -n "$PROXY_PID" ]; then
        kill "$PROXY_PID" 2>/dev/null
        wait "$PROXY_PID" 2>/dev/null
      fi

      /usr/bin/go-dispatch-proxy \
        -lhost 127.0.0.1 \
        -lport "$PPORT" \
        -tunnel "$FORMATTED_LOCALHOSTPORTS" &
      PROXY_PID=$!
    fi

    sleep 45
  done &
}

# Main execution
start_tor_clients
running_init_since
sleep 20
renew_circuits
start_dispatch_proxy

# Keep script running
wait
