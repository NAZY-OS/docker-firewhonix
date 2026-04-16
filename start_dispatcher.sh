#!/bin/bash

# Base port for Tor instances
TOR_PORT_BASE=9051  # Adjusted to the port range of the Docker script

# Maximum number of Tor instances
MAX_INSTANCES=12

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
  setcap cap_net_raw=eip /bin/go-dispatch-proxy
  /bin/go-dispatch-proxy -lport 4711 --tunnel $formatted_ports &

  echo "Started Dispatch Proxy on port 4711 with ports: $formatted_ports"
}

# Start processes
start_dispatch_proxy
