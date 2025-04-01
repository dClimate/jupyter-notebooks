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

# Retrieve the peer ID from IPFS config (ensure your node is initialized)
PEER_ID=$(ipfs config Identity.PeerID)
if [ -z "$PEER_ID" ]; then
    echo "Error: Unable to retrieve peer ID. Make sure your IPFS node is initialized."
    exit 1
fi
echo "Using peer ID: $PEER_ID"

# --- Configure Internal WebSocket Listeners ---
# Get current Addresses.Swarm and remove last bracket (to append entries)
# Use default [] if config key doesn't exist yet
EXISTING_SWARM=$(ipfs config Addresses.Swarm || echo "[]")
EXISTING_SWARM_CONTENT=$(echo "$EXISTING_SWARM" | sed 's/\[//g' | sed 's/\]//g' | sed 's/,$//g' | sed 's/^,//g') # Extract content inside []

# Define internal WebSocket listeners
WS_IPV4="/ip4/0.0.0.0/tcp/4001/ws"
WS_IPV6="/ip6/::/tcp/4001/ws"

# Initialize NEW_SWARM with current entries if any
if [ -n "$EXISTING_SWARM_CONTENT" ]; then
    NEW_SWARM="[$EXISTING_SWARM_CONTENT"
else
    NEW_SWARM="["
fi

needs_update=false
# Check if /ws entries are missing, then add them
if ! echo "$EXISTING_SWARM_CONTENT" | grep -q -F "$WS_IPV4"; then
    echo "Adding Internal WebSocket listener for IPv4..."
    if [ -n "$EXISTING_SWARM_CONTENT" ] && [[ "$NEW_SWARM" != "[" ]]; then NEW_SWARM="$NEW_SWARM,"; fi
    NEW_SWARM="$NEW_SWARM \"$WS_IPV4\""
    needs_update=true
fi

if ! echo "$EXISTING_SWARM_CONTENT" | grep -q -F "$WS_IPV6"; then
    echo "Adding Internal WebSocket listener for IPv6..."
    if [ -n "$EXISTING_SWARM_CONTENT" ] && [[ "$NEW_SWARM" != "[" ]] && [[ "$NEW_SWARM" != *"\"$WS_IPV4\""* ]]; then NEW_SWARM="$NEW_SWARM,"; fi # Add comma only if needed
    if [[ "$NEW_SWARM" != "[" && ! "$NEW_SWARM" =~ \",$ ]]; then NEW_SWARM="$NEW_SWARM,"; fi # Ensure comma if needed
    NEW_SWARM="$NEW_SWARM \"$WS_IPV6\""
    needs_update=true
fi

# Close JSON array
NEW_SWARM="$NEW_SWARM]"

# Apply the updated Swarm configuration only if changes were made
if [ "$needs_update" = true ] ; then
    echo "Updating Addresses.Swarm: $NEW_SWARM"
    ipfs config --json Addresses.Swarm "$NEW_SWARM"
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

# Start Jupyter Lab
echo "Starting Jupyter Lab..."
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.allow_origin='*'

# Keep container running if Jupyter exits (optional, for debugging)
# wait