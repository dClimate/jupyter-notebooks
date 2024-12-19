#!/bin/bash
# /scripts/install_packages.sh

# Function to install packages using UV
# install_packages() {
#     local req_file=$1
#     if [ -f "$req_file" ]; then
#         echo "Installing packages from $req_file..."
#         /root/.cargo/bin/uv pip install -r "$req_file"
#     fi
# }

# # Install from user's requirements file if it exists
# install_packages "/notebooks/requirements.txt"

# # Install from any additional requirements files in the requirements directory
# for req_file in /opt/requirements/*.txt; do
#     if [ -f "$req_file" ]; then
#         install_packages "$req_file"
#     fi
# done


#!/bin/bash

# Check if there are any additional requirement files
if [ -d "/opt/requirements" ]; then
    for req in /opt/requirements/*.txt; do
        if [ -f "$req" ]; then
            echo "Installing packages from $req"
            uv pip install --no-cache -r "$req"
        fi
    done
fi