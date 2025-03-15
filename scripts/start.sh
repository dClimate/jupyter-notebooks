#!/bin/bash
# /scripts/start.sh

# Install any new packages
# /scripts/install_packages.sh

# Debug Railway deployment
echo "=== Railway Debug ==="
echo "Working Directory: $(pwd)"
echo "Notebook Directory Contents:"
ls -la /notebooks

# Wait a bit for gitSync (if it's running)
sleep 10

echo "=== After Wait ==="
echo "Notebook Directory Contents:"
ls -la /notebooks

export GOLOG_LOG_LEVEL="error,autotls=debug"

# Detect Railway's TCP Proxy settings
if [[ -n "$RAILWAY_TCP_PROXY_DOMAIN" && -n "$RAILWAY_TCP_PROXY_PORT" ]]; then
    echo "Setting up IPFS to announce Railway TCP Proxy address..."

    # Construct the correct multiaddr without AutoTLS
    ANNOUNCE_ADDR="/dns4/$RAILWAY_TCP_PROXY_DOMAIN/tcp/$RAILWAY_TCP_PROXY_PORT/ws"

    # Apply it to IPFS configuration
    ipfs config --json Addresses.Announce "[\"$ANNOUNCE_ADDR\"]"
fi

# Get current Addresses.Swarm
EXISTING_SWARM=$(ipfs config --json Addresses.Swarm)

# Define WebSocket listeners
WS_IPV4="/ip4/0.0.0.0/tcp/4001/ws"
WS_IPV6="/ip6/::/tcp/4001/ws"

# Check if WebSockets are missing and append them
if ! echo "$EXISTING_SWARM" | grep -q "$WS_IPV4"; then
    echo "Adding WebSocket listener for IPv4..."
    ipfs config --json Addresses.Swarm "$(echo "$EXISTING_SWARM" | jq ". + [\"$WS_IPV4\"]")"
fi

if ! echo "$EXISTING_SWARM" | grep -q "$WS_IPV6"; then
    echo "Adding WebSocket listener for IPv6..."
    ipfs config --json Addresses.Swarm "$(echo "$EXISTING_SWARM" | jq ". + [\"$WS_IPV6\"]")"
fi

# Start IPFS daemon in the background
ipfs daemon --enable-pubsub-experiment --migrate=true &

# Wait for IPFS to start
sleep 5

# Start Jupyter
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.allow_origin='*'
