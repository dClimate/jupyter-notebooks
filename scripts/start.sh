#!/bin/bash
# /scripts/start.sh

# Debug Railway deployment
echo "=== Railway Debug ==="
echo "Working Directory: $(pwd)"
echo "Notebook Directory Contents:"
ls -la /notebooks || echo "/notebooks not found or empty yet"

# Wait a bit for potential gitSync or volume mounts
echo "Waiting 10s for services/sync..."
sleep 10

# Configure IPFS gateway to listen on both 
# ipfs config --json Addresses.Gateway '["/ip4/127.0.0.1/tcp/8080","/ip6/::1/tcp/8080"]'
# Listen on all available IPv4 and IPv6 interfaces on port 8080
ipfs config --json Addresses.Gateway '["/ip4/0.0.0.0/tcp/8080", "/ip6/::/tcp/8080"]'

# Configure IPFS API to listen on all interfaces <---
# This makes BOTH the RPC API (/api/v0/) and the WebUI (/webui) accessible externally
# Original "API": "/ip4/127.0.0.1/tcp/5001" default
ipfs config --json Addresses.API '["/ip4/0.0.0.0/tcp/5001", "/ip6/::/tcp/5001"]'

# Retrieve the peer ID from IPFS config (ensure your node is initialized)
PEER_ID=$(ipfs config Identity.PeerID)
if [ -z "$PEER_ID" ]; then
    echo "Error: Unable to retrieve peer ID. Make sure your IPFS node is initialized."
    exit 1
fi
echo "Using peer ID: $PEER_ID"

# --- Configure Internal WebSocket Listeners using jq ---
echo "Configuring Internal WebSocket listeners..."
ADDR1="/ip4/0.0.0.0/tcp/4001/ws"
ADDR2="/ip6/::/tcp/4001/ws"

# Get current swarm addresses, default to empty array '[]' if command fails or key missing
CURRENT_SWARM_JSON=$(ipfs config Addresses.Swarm || echo "[]")

# Use jq to add the desired addresses and ensure uniqueness
# '. + [$addr1, $addr2]' adds the new addresses (even if duplicate)
# '| unique' removes duplicates, resulting in the desired state
NEW_SWARM_JSON=$(echo "$CURRENT_SWARM_JSON" | jq --arg addr1 "$ADDR1" --arg addr2 "$ADDR2" \
    '(. + [$addr1, $addr2]) | unique')

# Check if the new JSON is different from the old one before applying
if [[ "$CURRENT_SWARM_JSON" != "$NEW_SWARM_JSON" ]]; then
    echo "Updating Addresses.Swarm to: $NEW_SWARM_JSON"
    ipfs config --json Addresses.Swarm "$NEW_SWARM_JSON"
    if [ $? -ne 0 ]; then
         echo "Error applying Swarm config!"
         # Optionally exit or add more error handling
    fi
else
    echo "Internal Addresses.Swarm already configured correctly."
fi

# --- Configure Public WebSocket Announce Address via Proxy ---
ANNOUNCE_ADDRS=()

# Check if the proxy URL environment variable is set by Railway
if [[ -n "$IPFS_WS_PROXY_URL" ]]; then
    echo "Proxy URL detected: $IPFS_WS_PROXY_URL"
    # Extract domain from the URL (handles http:// or https://)
    PROXY_DOMAIN=$(echo "$IPFS_WS_PROXY_URL" | sed -e 's|^[^/]*//||' -e 's|/.*$||')

    # Construct the public WebSocket announce address using /dns4/, /wss/ and the PeerID
    # Railway uses port 443 for its default HTTPS URLs
    WSS_ANNOUNCE_ADDR="/dns4/$PROXY_DOMAIN/tcp/443/wss/p2p/$PEER_ID"
    ANNOUNCE_ADDRS+=("$WSS_ANNOUNCE_ADDR")
    echo "Constructed Public WSS Announce Address: $WSS_ANNOUNCE_ADDR"
else
    echo "Warning: IPFS_WS_PROXY_URL environment variable not set. Cannot announce public WebSocket address."
fi

if [ ${#ANNOUNCE_ADDRS[@]} -gt 0 ]; then
    # Manually build a JSON array
    JSON_ADDRS="["
    for addr in "${ANNOUNCE_ADDRS[@]}"; do
        JSON_ADDRS+="\"$addr\","
    done
    JSON_ADDRS="${JSON_ADDRS%,}"  # remove trailing comma
    JSON_ADDRS+="]"

    echo "Setting Addresses.Announce: $JSON_ADDRS"
    ipfs config --json Addresses.Announce "$JSON_ADDRS"
else
    echo "No public addresses to announce. Clearing Addresses.Announce."
    # Clear existing announce addresses if none are configured now
    ipfs config --json Addresses.Announce "[]"
fi

# Clear AppendAnnounce as we are explicitly setting Announce
echo "Clearing Addresses.AppendAnnounce."
ipfs config --json Addresses.AppendAnnounce "[]"

# This tells your node not to disable NAT port mapping. May or may not be relevant
# behind the proxy, but keep it for now.
ipfs config --json Swarm.DisableNatPortMap false

# Remove AutoTLS config as Nginx proxy handles TLS termination
echo "Disabling Kubo AutoTLS as proxy handles TLS."
ipfs config --json AutoTLS.Enabled false
# ipfs config --json AutoTLS.AutoWSS false # This might not be needed if Enabled=false

echo "Final IPFS configuration check:"
echo "Addresses.Swarm:"
ipfs config Addresses.Swarm
echo "Addresses.Announce:"
ipfs config Addresses.Announce
echo "AutoTLS:"
ipfs config AutoTLS

# Start IPFS daemon in the background
echo "Starting IPFS daemon..."
ipfs daemon --enable-pubsub-experiment --migrate=true &

# # Wait for IPFS daemon to be ready
# echo "Waiting for IPFS daemon to start (15s)..."
# sleep 15
# ipfs swarm peers > /dev/null 2>&1
# if [ $? -ne 0 ]; then
#     echo "Warning: IPFS daemon might not be fully ready."
# else
#     echo "IPFS daemon seems responsive."
# fi

# Wait for IPFS to start
sleep 5

# Determine Jupyter token
JUPYTER_TOKEN_VALUE=${JUPYTER_TOKEN:-"default_token"}
echo "Using Jupyter token: $JUPYTER_TOKEN_VALUE"

# Start Jupyter Lab
echo "Starting Jupyter Lab..."
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token="$JUPYTER_TOKEN_VALUE" --NotebookApp.allow_origin='*' 

# Keep container running if Jupyter exits (optional, for debugging)
# wait