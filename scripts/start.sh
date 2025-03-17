#!/bin/bash
# /scripts/start.sh

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

# Retrieve the peer ID from IPFS config (ensure your node is initialized)
PEER_ID=$(ipfs config Identity.PeerID)
if [ -z "$PEER_ID" ]; then
    echo "Error: Unable to retrieve peer ID. Make sure your IPFS node is initialized."
    exit 1
fi
echo "Using peer ID: $PEER_ID"

# Define the WS address you want to add
WS_ADDR="/ip4/0.0.0.0/tcp/4001/ws"

# Get current swarm addresses as a JSON string
CURRENT_SWARM=$(ipfs config Addresses.Swarm)
echo "Current Swarm addresses: $CURRENT_SWARM"

# Check if the WS address is already in the array
if [[ "$CURRENT_SWARM" == *"$WS_ADDR"* ]]; then
  echo "WebSocket address already exists in swarm configuration."
  UPDATED_SWARM="$CURRENT_SWARM"
else
  # If the current array is empty "[]", then build a new array with WS_ADDR
  if [ "$CURRENT_SWARM" == "[]" ]; then
    UPDATED_SWARM='["'"$WS_ADDR"'"]'
  else
    # Remove the trailing ']' from CURRENT_SWARM and append the new address.
    UPDATED_SWARM="${CURRENT_SWARM%?},\"$WS_ADDR\"]"
  fi
  echo "Updated Swarm addresses: $UPDATED_SWARM"
  # Update the configuration
  ipfs config --json Addresses.Swarm "$UPDATED_SWARM"
fi

# Define the WS address you want to add
WS_ADDR="/ip4/0.0.0.0/tcp/4001/ws"

# Get current swarm addresses as a JSON string
CURRENT_SWARM=$(ipfs config Addresses.Swarm)
echo "Current Swarm addresses: $CURRENT_SWARM"

# Check if the WS address is already in the array
if [[ "$CURRENT_SWARM" == *"$WS_ADDR"* ]]; then
  echo "WebSocket address already exists in swarm configuration."
  UPDATED_SWARM="$CURRENT_SWARM"
else
  # If the current array is empty "[]", then build a new array with WS_ADDR
  if [ "$CURRENT_SWARM" == "[]" ]; then
    UPDATED_SWARM='["'"$WS_ADDR"'"]'
  else
    # Remove the trailing ']' from CURRENT_SWARM and append the new address.
    UPDATED_SWARM="${CURRENT_SWARM%?},\"$WS_ADDR\"]"
  fi
  echo "Updated Swarm addresses: $UPDATED_SWARM"
  # Update the configuration
  ipfs config --json Addresses.Swarm "$UPDATED_SWARM"
fi
# Build the list of announce addresses for IPFS
ANNOUNCE_ADDRS=()

if [[ -n "$RAILWAY_TCP_PROXY_DOMAIN" && -n "$RAILWAY_TCP_PROXY_PORT" ]]; then
    echo "Adding TCP proxy address for IPFS (plain TCP)..."
    # Announce for TCP connections with peer ID appended
    TCP_ADDR="/dns4/$RAILWAY_TCP_PROXY_DOMAIN/tcp/$RAILWAY_TCP_PROXY_PORT/tls/sni/$RAILWAY_TCP_PROXY_DOMAIN/ipfs/$PEER_ID"
    ANNOUNCE_ADDRS+=("$TCP_ADDR")

    echo "Adding public domain address for WebSocket connections..."
    # Announce for WebSocket connections using the same external mapping,
    # with '/ws' appended.
    WS_ADDR="/dns4/$RAILWAY_TCP_PROXY_DOMAIN/tcp/$RAILWAY_TCP_PROXY_PORT/tls/sni/$RAILWAY_TCP_PROXY_DOMAIN/ws/ipfs/$PEER_ID"
    ANNOUNCE_ADDRS+=("$WS_ADDR")
fi

if [ ${#ANNOUNCE_ADDRS[@]} -gt 0 ]; then
    # Manually build a JSON array without jq
    JSON_ADDRS="["
    for addr in "${ANNOUNCE_ADDRS[@]}"; do
        JSON_ADDRS+="\"$addr\","
    done
    JSON_ADDRS="${JSON_ADDRS%,}"  # remove trailing comma
    JSON_ADDRS+="]"
    
    echo "Announcing addresses: $JSON_ADDRS"
    ipfs config --json Addresses.Announce "$JSON_ADDRS"
fi

# Start IPFS daemon in the background
ipfs daemon --enable-pubsub-experiment --migrate=true &

# Wait for IPFS to start
sleep 5

# Start Jupyter Lab
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.allow_origin='*'