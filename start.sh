#!/bin/bash

# Base port for Tor instances (SOCKS proxies)
TOR_PORT_BASE=9061  # Adjust to the port range used by your Docker/script setup

# Maximum number of Tor instances
MAX_INSTANCES=12

start_tor_clients() {
  # Use a temporary directory in RAM (e.g., tmpfs)
  base_tmp_dir="/mnt/ramdisk"  # Ensure this path exists or is mountable

  # Mount tmpfs to keep Tor data in memory (best performance)
  mount -t tmpfs -o size=1G tmpfs "$base_tmp_dir" 2> /dev/null

  # Track ports (optional; the original script tries to store them)
  ports=""

  for i in $(seq 1 $MAX_INSTANCES); do
    # Compute the SOCKS port for this instance
    port=$((TOR_PORT_BASE + i - 1))

    # Save SOCKS port (for later writing into /tmp/tor_ports)
    if [ -z "$ports" ]; then
      ports="$port"
    else
      ports="$ports,$port"
    fi

    # Create a unique folder for each Tor instance
    tor_data_dir="$base_tmp_dir/tor_instance_$port"
    mkdir -p "$tor_data_dir"

    # Set ownership so the tor user can write its data directory
    chown tor:tor "$tor_data_dir"

    # IMPORTANT:
    # You requested "Control ports" should be 100 higher than the SOCKS port.
    # That means: ControlPort = SocksPort + 100
    sudo tor --User tor --SocksPort "$port" --ControlPort "$((port + 100))" \
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

    # Log started instance (visible)
    echo "Started Tor client on SOCKS port $port with data directory $tor_data_dir (ControlPort=$((port+100)))"

    # Give Tor a moment to start
    sleep 1
  done

  # Save the SOCKS ports in a temporary file (space-separated)
  echo "${ports//,/ }" > /tmp/tor_ports
}

# Signal processing loop:
# Every cycle, check running Tor process count; if >= threshold, signal them to renew circuits.
while true; do
  # Wait before checking process count
  sleep 90

  # Count number of Tor processes
  count=$(pidof tor | wc -w)

  # If at least 10 Tor instances are running, renew circuits for all of them
  if [ "$count" -ge 10 ]; then
    echo "There are at least 10 instances of Tor running."

    for pid in $(pidof tor); do
      # Send USR1 to trigger Tor to renew circuits (as per Tor's signal handling)
      kill -USR1 "$pid"
      echo "Renewing circuit for PID $pid"
    done

  else
    # If fewer than threshold Tor instances are running, wait a bit and try again
    sleep 30
    continue
  fi

  # Random delay between 300 and 600 seconds to stagger renewals
  sleep $((RANDOM % 301 + 300))
done &

# Start dnscrypt-proxy client (disabled/commented in your script)
# dnscrypt-proxy -config /etc/dnscrypt-proxy/dnscrypt-proxy.toml &

# Start stubby (DNS-over-TLS proxy)
stubby -l &

# Start dispatcher and Tor clients
/sbin/start_dispatcher.sh &
start_tor_clients
