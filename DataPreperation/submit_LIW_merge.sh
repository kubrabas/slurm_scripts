#!/bin/bash
#SBATCH --time=00:30:00
#SBATCH --account=def-nahee
#SBATCH --mem=8G
#SBATCH --cpus-per-task=1
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null

# Runs automatically after the LIW array job finishes (any outcome).
# Parameters come from submit_LIW.py via --export:
#   MC, FLAVOR, LOGDIR

set -euo pipefail

mkdir -p "${LOGDIR}"

LOGFILE="${LOGDIR}/merge_${FLAVOR}.out"
MERGE_SCRIPT="/project/def-nahee/kbas/Graphnet-Applications/DataPreperation/EventWeights/LIW/merge_LIW.py"

echo "--- HOST: JOB=${SLURM_JOB_ID:-} HOST=$(hostname)"
echo "--- CONFIG: MC=${MC}  FLAVOR=${FLAVOR}"

module --force purge
module load StdEnv/2020 python/3.11 scipy-stack/2023b

python3 -u "${MERGE_SCRIPT}" \
    --mc "${MC}" \
    --flavor "${FLAVOR}" \
    2>&1 | tee "${LOGFILE}"

rc=${PIPESTATUS[0]}
echo "--- merge finished (rc=${rc})"
exit $rc
