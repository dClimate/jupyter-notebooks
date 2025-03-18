#!/bin/bash
# /scripts/digitalocean_start.sh
# Dedicated startup script for Digital Ocean App Platform

# Debug deployment info
echo "=== Digital Ocean App Platform Deployment ==="
echo "Working Directory: $(pwd)"
echo "Notebook Directory Contents:"
ls -la /notebooks

# Enable AutoTLS debug logging
export GOLOG_LOG_LEVEL="error,autotls=debug"

# Retrieve the peer ID from IPFS config (ensure your node is initialized)
PEER_ID=$(ipfs config Identity.PeerID)
if [ -z "$PEER_ID" ]; then
    echo "Error: Unable to retrieve peer ID. Make sure your IPFS node is initialized."
    exit 1
fi
echo "Using peer ID: $PEER_ID"

# Digital Ocean App Platform specific configuration
echo "Configuring IPFS for Digital Ocean App Platform..."

# Get the public-facing URL assigned by Digital Ocean
if [ -n "$APP_URL" ]; then
    APP_DOMAIN=$(echo "$APP_URL" | sed 's|^https?://||' | sed 's|/.*$||')
    
    echo "App domain: $APP_DOMAIN"
    
    # Configure announce addresses
    DO_ANNOUNCE_ADDRS="[\"/dns4/$APP_DOMAIN/tcp/443/https\"]"
    echo "Setting announce addresses: $DO_ANNOUNCE_ADDRS"
    ipfs config --json Addresses.Announce "$DO_ANNOUNCE_ADDRS"
else
    echo "No APP_URL environment variable found"
fi

# Disable NAT port mapping in cloud environment
ipfs config --json Swarm.DisableNatPortMap true

# Enable AutoTLS settings.
ipfs config --json AutoTLS.Enabled true
ipfs config --json AutoTLS.AutoWSS true

echo "Current AutoTLS configuration:"
ipfs config AutoTLS

# Install any additional packages from requirements files
if [ -f "/scripts/install_packages.sh" ]; then
    echo "Running install_packages.sh..."
    /scripts/install_packages.sh
fi

# Start IPFS daemon in the background
echo "Starting IPFS daemon..."
ipfs daemon --enable-pubsub-experiment --migrate=true &

# Wait for IPFS to start
sleep 5

# Determine Jupyter token
JUPYTER_TOKEN_VALUE=${JUPYTER_TOKEN:-"default_token"}
echo "Using Jupyter token: $JUPYTER_TOKEN_VALUE"

# Start Jupyter Lab
echo "Starting Jupyter Lab..."
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token="$JUPYTER_TOKEN_VALUE" --NotebookApp.allow_origin='*' 