#!/bin/bash
#SBATCH --account=def-nahee
#SBATCH --time=04:00:00
#SBATCH --mem=48G
#SBATCH --gpus-per-node=nvidia_h100_80gb_hbm3_3g.40gb:1
#SBATCH --cpus-per-task=8
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null

# Parameters via --export from submit_classification_pipeline.py:
#   CONFIG, LOGFILE

set -euo pipefail

mkdir -p "$(dirname "${LOGFILE}")"

module --force purge
module load StdEnv/2020 gcc/11.3.0 apptainer scipy-stack/2023b

GRAPHNET_SRC="/project/def-nahee/kbas/graphnet/src"
EXAMPLE_DIR="/project/def-nahee/kbas/graphnet/examples/08_pone"
TEST_SCRIPT="${EXAMPLE_DIR}/05_test_classification.py"
IMAGE="docker://rorsoe/graphnet:graphnet-1.8.0-cu126-torch26-ubuntu-22.04"

echo "--- HOST: JOB=${SLURM_JOB_ID:-}  HOST=$(hostname)"
echo "--- CONFIG: ${CONFIG}"
echo "--- LOGFILE: ${LOGFILE}"

apptainer exec --nv --cleanenv \
  --env PYTHONNOUSERSITE=1 \
  --env PYTHONPATH="${GRAPHNET_SRC}:${EXAMPLE_DIR}" \
  --bind /project \
  "${IMAGE}" \
  python3 -u "${TEST_SCRIPT}" --config "${CONFIG}" \
  2>&1 | tee "${LOGFILE}"

rc=${PIPESTATUS[0]}
echo "--- test_classification finished (rc=${rc})"
exit $rc
