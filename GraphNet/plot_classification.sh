#!/bin/bash
#SBATCH --account=def-nahee
#SBATCH --time=00:30:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=2
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null

# Parameters via --export from submit_classification_pipeline.py:
#   CONFIG, LOGFILE, PREDICTIONS_CSV

set -euo pipefail

mkdir -p "$(dirname "${LOGFILE}")"

module --force purge
module load StdEnv/2020 gcc/11.3.0 apptainer scipy-stack/2023b

GRAPHNET_SRC="/project/def-nahee/kbas/graphnet/src"
EXAMPLE_DIR="/project/def-nahee/kbas/graphnet/examples/08_pone"
PLOT_SCRIPT="${EXAMPLE_DIR}/07_plot_classification_results.py"
IMAGE="docker://rorsoe/graphnet:graphnet-1.8.0-cu126-torch26-ubuntu-22.04"

echo "--- HOST: JOB=${SLURM_JOB_ID:-}  HOST=$(hostname)"
echo "--- CONFIG: ${CONFIG}"
echo "--- PREDICTIONS_CSV: ${PREDICTIONS_CSV}"
echo "--- LOGFILE: ${LOGFILE}"

apptainer exec --cleanenv   --env PYTHONNOUSERSITE=1   --env PYTHONPATH="${GRAPHNET_SRC}:${EXAMPLE_DIR}"   --bind /project   "${IMAGE}"   python3 -u "${PLOT_SCRIPT}" "${PREDICTIONS_CSV}"   2>&1 | tee "${LOGFILE}"

rc=${PIPESTATUS[0]}
echo "--- plot_classification finished (rc=${rc})"
exit $rc
