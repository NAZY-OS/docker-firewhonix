#!/bin/bash


echo
echo
echo ________________________________________________
echo
echo Starting go-dispatcher for Loadbalancing Tor!
echo
echo ________________________________________________


# Base port for Tor instances
TOR_PORT_BASE=9061  # Adjusted to the port range of the Docker script

# Loadbalancer Port
PPORT=4711

# Maximum number of Tor instances
MAX_INSTANCES=12

running_init_since() {
    local start_text
    start_text=$(date '+%Y-%m-%d.%H:%M:%S')

    echo "Firewhonix Loadbalancer is running since $start_text"

    (
        while true; do
            sleep 15

            # Reset the count on every loop
            local pid_count=0
            local pids
            pids=$(pidof tor 2>/dev/null || true)

            if [[ -n "$pids" ]]; then
                local -a pid_array
                read -r -a pid_array <<< "$pids"
                pid_count=${#pid_array[@]}
            fi

            echo "Firewhonix is running with $pid_count PIDs"
        done
    ) &
}


start_dispatch_proxy() {
  # Create the ports string without SOCKS
  ports=$(seq $((TOR_PORT_BASE)) $((TOR_PORT_BASE + MAX_INSTANCES - 1)))
  formatted_ports=""

  for port in ${ports}; do
    formatted_ports+="127.0.0.1:${port} "  # Add ports in the desired format
  done

  # Remove the last space
  formatted_ports=${formatted_ports% }

  # Start the Dispatch Proxy with the specified options
  /usr/bin/go-dispatch-proxy -lhost 127.0.0.1 -lport ${PPORT} -tunnel  $formatted_ports &
  echo "Started Dispatch Proxy on port 127.0.1:${PPORT}"
  echo 
  echo "Balancing to this ip + ports: $formatted_ports"
  echo
  running_init_since
}

# Start processes
start_dispatch_proxy
