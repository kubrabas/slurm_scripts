#!/bin/bash
#SBATCH --time=04:00:00
#SBATCH --account=def-nahee
#SBATCH --mem=32G
#SBATCH --cpus-per-task=4
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null

# Runs automatically after the Parquet array job finishes (any outcome).
# Parameters come from submit_parquet.py via --export:
#   MC, FLAVOR, GEOMETRY, OUTDIR, LOGDIR

set -euo pipefail

mkdir -p "${LOGDIR}"

GRAPHNET_SRC="/project/def-nahee/kbas/graphnet/src"
MERGE_SCRIPT="/project/def-nahee/kbas/Graphnet-Applications/DataPreperation/Parquet/merge_parquet.py"

echo "--- HOST: JOB=${SLURM_JOB_ID:-} HOST=$(hostname)"
echo "--- CONFIG: MC=${MC}  FLAVOR=${FLAVOR}  GEOMETRY=${GEOMETRY}"

module --force purge
module load StdEnv/2020 python/3.11 scipy-stack/2023b

export PYTHONPATH="${GRAPHNET_SRC}:${PYTHONPATH:-}"
export PYTHONUNBUFFERED=1

python3 -u "${MERGE_SCRIPT}" \
    --mc       "${MC}" \
    --flavor   "${FLAVOR}" \
    --geometry "${GEOMETRY}" \
    --outdir   "${OUTDIR}" \
    --logdir   "${LOGDIR}" \
    --num-workers 4

rc=$?
echo "--- merge finished (rc=${rc})"
exit $rc
