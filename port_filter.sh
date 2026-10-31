#!/bin/sh
# =============================================
# Port Filter Script for Alpine Linux (Docker)
# - Uses nftables (pre-installed in Alpine)
# - Supports:
#   - `-p` / `--allowPort`: Whitelist ports (only these are allowed)
#   - `--dropPort`: Blacklist ports (block these)
# - Example:
#   ./port_filter.sh -p 80 443 --dropPort 8080 3000
# =============================================

# --- Help message ---
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -p, --allowPort PORT1 PORT2 ...  Whitelist ports (only these are allowed)"
    echo "  --dropPort PORT1 PORT2 ...       Blacklist ports (block these)"
    echo "  -h, --help                       Show this help"
    echo ""
    echo "Example:"
    echo "  $0 -p 80 443 --dropPort 8080 3000"
    exit 1
}

# --- Parse arguments with getopts ---
ALLOW_PORTS=""
DROP_PORTS=""

while [ $# -gt 0 ]; do
    case "$1" in
        -p|--allowPort)
            shift
            while [ $# -gt 0 ] && ! echo "$1" | grep -q '^-'; do
                ALLOW_PORTS="$ALLOW_PORTS $1"
                shift
            done
            ;;
        --dropPort)
            shift
            while [ $# -gt 0 ] && ! echo "$1" | grep -q '^-'; do
                DROP_PORTS="$DROP_PORTS $1"
                shift
            done
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Error: Unknown option $1"
            show_help
            ;;
    esac
done

# --- Validate inputs ---
if [ -z "$ALLOW_PORTS" ] && [ -z "$DROP_PORTS" ]; then
    echo "Error: No ports specified. Use -p or --dropPort."
    show_help
fi

# --- Initialize nftables table (if not exists) ---
nft list tables | grep -q "inet filter" || {
    echo "[INFO] Creating nftables table..."
    nft add table inet filter
    nft add chain inet filter input { type filter hook input priority 0 \; }
    nft add chain inet filter output { type filter hook output priority 0 \; }
}

# --- Apply ALLOW rules (whitelist) ---
if [ -n "$ALLOW_PORTS" ]; then
    echo "[INFO] Allowing ports: $ALLOW_PORTS"
    for port in $ALLOW_PORTS; do
        nft add rule inet filter input tcp dport "$port" accept
        nft add rule inet filter input udp dport "$port" accept
        nft add rule inet filter output tcp dport "$port" accept
        nft add rule inet filter output udp dport "$port" accept
        echo "[OK] Port $port (TCP/UDP) allowed."
    done
fi

# --- Apply DROP rules (blacklist) ---
if [ -n "$DROP_PORTS" ]; then
    echo "[INFO] Blocking ports: $DROP_PORTS"
    for port in $DROP_PORTS; do
        nft add rule inet filter input tcp dport "$port" drop
        nft add rule inet filter input udp dport "$port" drop
        nft add rule inet filter output tcp dport "$port" drop
        nft add rule inet filter output udp dport "$port" drop
        echo "[OK] Port $port (TCP/UDP) blocked."
    done
fi

# --- Allow loopback and established connections ---
nft add rule inet filter input iif lo accept
nft add rule inet filter input ct state established,related accept
nft add rule inet filter output oif lo accept
nft add rule inet filter output ct state established,related accept

# --- Show active rules ---
echo "[INFO] Active nftables rules:"
nft list ruleset

echo "[SUCCESS] Port filtering applied!"
