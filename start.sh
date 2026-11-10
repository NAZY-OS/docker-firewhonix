#!/bin/bash

# Configuration
TOR_PORT_BASE=9061          # Base port for Tor SOCKS proxies
MAX_INSTANCES=12            # Number of Tor instances to run
BASE_TMP_DIR="/mnt/ramdisk" # Temporary directory for Tor data
DISPATCHER_PORT=4711        # Port for go-dispatch-proxy

# Load existing Tor ports or initialize if empty
if [ -f /tmp/tor_ports ]; then
    read -r PORTS < /tmp/tor_ports
else
    PORTS=""
fi

# Format ports for go-dispatch-proxy (space-separated)
FORMATTED_PORTS=$(echo "$PORTS" | tr ',' ' ')

start_tor_clients() {
    # Create tmpfs for in-memory storage
    mount -t tmpfs -o size=1G tmpfs "$BASE_TMP_DIR" 2>/dev/null

    # Start Tor instances
    for I in $(seq 1 "$MAX_INSTANCES"); do
        PORT=$((TOR_PORT_BASE + I - 1))
        TOR_DATA_DIR="$BASE_TMP_DIR/tor_instance_$PORT"

        # Initialize ports list
        if [ -z "$PORTS" ]; then
            PORTS="127.0.0.1:$PORT"
        else
            PORTS="$PORTS 127.0.0.1:$PORT"
        fi

        # Create and configure instance directory
        mkdir -p "$TOR_DATA_DIR"
        chown tor:tor "$TOR_DATA_DIR"

        # Start Tor instance
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

    # Save ports to file
    echo "$PORTS" > /tmp/tor_ports
    FORMATTED_PORTS=$(echo "$PORTS" | tr ',' ' ')
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
    echo "Firewhonix Load Balancer Started"
    echo "==============================================="
    echo

    START_TIME=$(date '+%Y-%m-%d %H:%M:%S')
    echo "System started at: $START_TIME"
    echo

    (
        while true; do
            sleep 15
            PID_COUNT=$(pidof tor 2>/dev/null | wc -w)
            ACTIVE_PIDS=$(pidof tor 2>/dev/null)

            echo "==============================================="
            echo "Firewhonix Status Report"
            echo "-----------------------------------------------"
            echo "Active Tor processes: $PID_COUNT"
            echo "Configured ports: $FORMATTED_PORTS"
            echo "go-dispatch-proxy configuration:"
            echo "  - Listening host: 127.0.0.1"
            echo "  - Listening port: $DISPATCHER_PORT"
            echo "  - Mode: tunnel"
            echo "  - Backend ports: $FORMATTED_PORTS"
            echo "-----------------------------------------------"
            echo "Active PIDs: $ACTIVE_PIDS"
            echo "==============================================="
        done
    ) &
}

start_dispatch_proxy() {
    echo "Starting go-dispatch-proxy with configuration:"
    echo "/usr/bin/go-dispatch-proxy -lhost 127.0.0.1 -lport $DISPATCHER_PORT -tunnel $FORMATTED_PORTS"
    echo

    while true; do
        if [ -n "$PROXY_PID" ]; then
            kill "$PROXY_PID" 2>/dev/null
            wait "$PROXY_PID" 2>/dev/null
        fi

        /usr/bin/go-dispatch-proxy \
            -lhost 127.0.0.1 \
            -lport "$DISPATCHER_PORT" \
            -tunnel \
            $FORMATTED_PORTS &
        PROXY_PID=$!

        sleep 45
    done &
}

# Main execution
cleanup() {
    echo "Cleaning up..."
    umount "$BASE_TMP_DIR" 2>/dev/null
    rm -f /tmp/tor_ports
    exit 0
}

trap cleanup EXIT INT TERM

start_tor_clients
running_init_since
sleep 20
renew_circuits
start_dispatch_proxy

wait
