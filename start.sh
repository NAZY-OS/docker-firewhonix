#!/bin/bash

# Base port for Tor instances
TOR_PORT_BASE=9051  # Adjusted to the port range of the Docker script

# Maximum number of Tor instances
MAX_INSTANCES=12

start_tor_clients() {
  # Use a temporary directory in RAM (e.g., tmpfs)
  base_tmp_dir="/mnt/ramdisk"  # Make sure this is created

  # Create the directory if it does not exist
  mkdir -p "$base_tmp_dir"

  for i in $(seq 1 $MAX_INSTANCES); do
    port=$((TOR_PORT_BASE + i - 1))

    # Create a unique folder for each Tor instance
    tor_data_dir="$base_tmp_dir/tor_instance_$port"
    mkdir -p "$tor_data_dir"
    
    # Change the ownership of the folder
    chown toranon:toranon "$tor_data_dir"
    
    # Start the Tor instance with specific parameters and redirect output
    sudo tor --User toranon --SocksPort "$port" --ControlPort "$((port + 100))" \
        --DataDirectory "$tor_data_dir" \
        --Sandbox 1 \
        --HardwareAccel 1 \
        --BandwidthBurst 1547483647 \
        --BandwidthRate 1547483647 \
        --ExcludeExitNodes '{us},{uk},{ca},{au},{nz},{dk},{fr},{nl},{no},{de},{be},{se},{es},{it},{at},{fi},{ru}' \
        --ClientOnly 1 \
        --DisableNetwork 0 \
        --UseBridges 0 \
        --DisableDebuggerAttachment 1 \
        --AvoidDiskWrites 1 1> /dev/null &

    echo "Started Tor client on port $port with data directory $tor_data_dir"
    sleep 1  # Ensure Tor has time to start
  done

  # Save the ports in a temporary file
  echo "${ports//,/ }" > /tmp/tor_ports
}

# Signal processing loop
while true; do
  sleep 120
  count=$(pidof tor | wc -w)
  if [ "$count" -ge 10 ]; then
      echo "There are at least 10 instances of Tor running."
  for pid in $(pidof tor); do
    kill -USR1 $pid
    echo "Renewing circuit for $pid"
  done
  
  else
      sleep 30
  fi
  sleep $((RANDOM % 301 + 300))
  
done &

# Start processes
/sbin/start_dispatcher.sh &
start_tor_clients
