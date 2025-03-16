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


# Get current Addresses.Swarm and remove last bracket (to append entries)
EXISTING_SWARM=$(ipfs config Addresses.Swarm | tr -d '[]' | tr -d '\n')

# Define WebSocket listeners
WS_IPV4="/ip4/0.0.0.0/tcp/4001/ws"
WS_IPV6="/ip6/::/tcp/4001/ws"

# Initialize NEW_SWARM with current entries
NEW_SWARM="[$EXISTING_SWARM"

# Check if /ws entries are missing, then add them
if ! echo "$EXISTING_SWARM" | grep -q "$WS_IPV4"; then
    echo "Adding WebSocket listener for IPv4..."
    NEW_SWARM="$NEW_SWARM, \"$WS_IPV4\""
fi

if ! echo "$EXISTING_SWARM" | grep -q "$WS_IPV6"; then
    echo "Adding WebSocket listener for IPv6..."
    NEW_SWARM="$NEW_SWARM, \"$WS_IPV6\""
fi

# Close JSON array
NEW_SWARM="$NEW_SWARM]"

# Apply the updated Swarm configuration
ipfs config --json Addresses.Swarm "$NEW_SWARM"

# Start IPFS daemon in the background
ipfs daemon --enable-pubsub-experiment --migrate=true &

# Wait for IPFS to start
sleep 5

# Start Jupyter
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.allow_origin='*'
