#!/bin/bash
# Usage: bash start_icetray_jupyter.sh [port]

PORT=${1:-8888}
ACCOUNT=def-nahee
TIME=1:30:00
MEM=24G
GPU=nvidia_h100_80gb_hbm3_1g.10gb:1
CONTAINER=/cvmfs/software.pacific-neutrino.org/containers/itray_v1.17.1
TMPLOG=$(mktemp /tmp/jupyter_log.XXXXX)

cleanup() {
    echo ""
    echo "Shutting down..."
    [ -n "$SALLOC_PID" ] && kill "$SALLOC_PID" 2>/dev/null
    rm -f "$TMPLOG"
    exit 0
}
trap cleanup INT TERM

echo "Requesting compute node... (${TIME}, ${MEM}, GPU: ${GPU})"

salloc --time="$TIME" --account="$ACCOUNT" --mem="$MEM" \
       --gpus-per-node="$GPU" \
    srun bash -c '
        module load StdEnv/2020 gcc/11.3.0 apptainer scipy-stack/2023b
        apptainer exec --nv '"$CONTAINER"' \
            /usr/bin/jupyter notebook --no-browser --ip=127.0.0.1 --port='"$PORT"' 2>&1
    ' >> "$TMPLOG" 2>&1 &
SALLOC_PID=$!

echo "Waiting for node allocation..."
NODE=""
for i in $(seq 1 60); do
    sleep 3
    NODE=$(grep -m1 "salloc: Nodes .* are ready" "$TMPLOG" 2>/dev/null | awk '{print $3}')
    [ -n "$NODE" ] && break
done

if [ -z "$NODE" ]; then
    echo "ERROR: Could not get compute node. Log:"
    cat "$TMPLOG"
    cleanup
fi
echo "Got node: $NODE"

echo "Waiting for Jupyter to start..."
URL=""
for i in $(seq 1 40); do
    sleep 3
    URL=$(grep -o "http://127\.0\.0\.1[^[:space:]]*token=[^[:space:]]*" "$TMPLOG" 2>/dev/null | head -1)
    [ -n "$URL" ] && break
done

if [ -z "$URL" ]; then
    echo "ERROR: Jupyter did not start. Log:"
    cat "$TMPLOG"
    cleanup
fi

ACTUAL_PORT=$(echo "$URL" | grep -o ':[0-9]*/' | head -1 | tr -d ':/')
[ -z "$ACTUAL_PORT" ] && ACTUAL_PORT=$PORT

echo ""
echo "==========================================================="
echo "  Jupyter is ready!"
echo "  Node   : $NODE"
echo "  Port   : $ACTUAL_PORT"
echo ""
echo "  Step 1 — Open a NEW terminal and run:"
echo "  bash ~/slurm_scripts/tunnel_to_node.sh $NODE $ACTUAL_PORT"
echo ""
echo "  Step 2 — Connect in VS Code (Existing Jupyter Server):"
echo "  $URL"
echo "==========================================================="
echo ""
echo "Press Ctrl+C to stop Jupyter."

wait "$SALLOC_PID"
cleanup
