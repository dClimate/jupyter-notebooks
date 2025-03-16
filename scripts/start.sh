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

# Build the list of announce addresses for IPFS
ANNOUNCE_ADDRS=()

if [[ -n "$RAILWAY_TCP_PROXY_DOMAIN" && -n "$RAILWAY_TCP_PROXY_PORT" ]]; then
    echo "Adding TCP proxy address for IPFS..."
    # This address is for TCP-based connections (Kubo nodes)
    TCP_ADDR="/dns4/$RAILWAY_TCP_PROXY_DOMAIN/tcp/$RAILWAY_TCP_PROXY_PORT/tls/sni/$RAILWAY_TCP_PROXY_DOMAIN/ws"
    ANNOUNCE_ADDRS+=("$TCP_ADDR")
fi

if [[ -n "$RAILWAY_PUBLIC_DOMAIN" ]]; then
    echo "Adding public domain address for WebSocket connections..."
    # This address is for WebSocket connections (for Helia/browser clients)
    WS_ADDR="/dns4/$RAILWAY_PUBLIC_DOMAIN/tcp/443/tls/sni/$RAILWAY_PUBLIC_DOMAIN/ws"
    ANNOUNCE_ADDRS+=("$WS_ADDR")
fi

if [ ${#ANNOUNCE_ADDRS[@]} -gt 0 ]; then
    # Build a JSON array manually in Bash
    JSON_ADDRS="["
    for addr in "${ANNOUNCE_ADDRS[@]}"; do
        JSON_ADDRS+="\"$addr\","
    done
    # Remove trailing comma and close the JSON array
    JSON_ADDRS="${JSON_ADDRS%,}"
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
