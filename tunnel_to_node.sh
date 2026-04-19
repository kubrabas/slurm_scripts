#!/bin/bash
# Usage: bash tunnel_to_node.sh <node> [port]

NODE=$1
PORT=${2:-8888}

if [ -z "$NODE" ]; then
    echo "Usage: $0 <node> [port]"
    exit 1
fi

echo "Tunnel: localhost:${PORT} -> ${NODE}:${PORT}  (Ctrl+C to close)"
ssh -N -L "${PORT}:localhost:${PORT}" "$NODE"
