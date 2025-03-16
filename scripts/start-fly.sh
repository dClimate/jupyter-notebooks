#!/bin/bash

# Create data directories if they don't exist
mkdir -p /data/ipfs /data/venv /data/notebooks

# Install any additional packages
/scripts/install_packages.sh

echo "=== Fly.io Deployment ==="
echo "Working Directory: $(pwd)"
echo "Notebook Directory Contents:"
ls -la /notebooks

# Initialize IPFS with defaults if not already initialized
if [ ! -f "/root/.ipfs/config" ]; then
    echo "Initializing IPFS..."
    ipfs init
fi

# Set IPFS log level
export GOLOG_LOG_LEVEL="error"

# Start IPFS daemon in the background
echo "Starting IPFS daemon..."
ipfs daemon --enable-pubsub-experiment --migrate=true &

# Wait for IPFS to start
sleep 5

# Start echo server in the background (if needed)
if [ -f "/echo-server/echo-server.js" ]; then
    echo "Starting Echo Server..."
    node /echo-server/echo-server.js &
fi

# Start Jupyter
echo "Starting Jupyter Lab..."
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.allow_origin='*' 