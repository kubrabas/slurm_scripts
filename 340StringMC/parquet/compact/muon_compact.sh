#!/bin/bash
#SBATCH --job-name=PQ_compact_muon_convert_merge_split
#SBATCH --time=12:00:00
#SBATCH --account=def-nahee
#SBATCH --mem=128G
#SBATCH --cpus-per-task=20
#SBATCH --output=/scratch/kbas/FinalParquetDatasets/logs/PQ_compact_muon_nonoise/%j.out
#SBATCH --error=/scratch/kbas/FinalParquetDatasets/logs/PQ_compact_muon_nonoise/%j.out
#SBATCH --open-mode=append

set -euo pipefail

GEOMETRY="compact"
FLAVOR="muon"

LOGDIR="/scratch/kbas/FinalParquetDatasets/logs/PQ_${GEOMETRY}_$(echo "${FLAVOR}" | tr '[:upper:]' '[:lower:]')_nonoise"
mkdir -p "${LOGDIR}"

echo "--- HOST: JOB=${SLURM_JOB_ID:-} HOST=$(hostname)"
echo "--- HOST: CPUS_PER_TASK=${SLURM_CPUS_PER_TASK:-unset}"
echo "--- HOST: GEOMETRY=${GEOMETRY}"
echo "--- HOST: FLAVOR=${FLAVOR}"

module purge
module load StdEnv/2020 gcc/11.3.0 apptainer scipy-stack/2023b

PONE_ENV_DIR="/project/def-nahee/kbas/pone_offline"
EXPORTS_FILE="${PONE_ENV_DIR}/icetray_exports.sh"
CONTAINER="/cvmfs/software.pacific-neutrino.org/containers/itray_v1.15.3"

PYTHON_SCRIPT="/project/def-nahee/kbas/Graphnet-Applications/DataPreperation/prepare_parquet.py"

# Keep CPU thread oversubscription under control
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export PYTHONUNBUFFERED=1

# Avoid host env leakage
unset I3_SHELL || true
unset I3_BUILD || true

echo "--- HOST: launching apptainer exec (no srun)"

apptainer exec "${CONTAINER}" bash -cx " \
  set -euo pipefail; \
  export PONE_GEOMETRY='${GEOMETRY}'; \
  export PONE_FLAVOR='${FLAVOR}'; \
  echo '--- CONTAINER: HOST=' \$(hostname); \
  cd '${PONE_ENV_DIR}'; \
  if [ -f '${EXPORTS_FILE}' ]; then \
     echo '--- CONTAINER: sourcing exports: ${EXPORTS_FILE}'; \
     source '${EXPORTS_FILE}'; \
  else \
     echo 'ERROR: exports file not found: ${EXPORTS_FILE}'; exit 2; \
  fi; \
  echo '--- CONTAINER: python3=' \$(command -v python3); \
  python3 -V; \
  echo '--- CONTAINER: env (I3_|PYTHONPATH|LD_LIBRARY_PATH|PONE_)'; \
  env | egrep 'I3_|PYTHONPATH|LD_LIBRARY_PATH|PONE_' || true; \
  echo '--- CONTAINER: running python (hardcoded config inside script)'; \
  python3 -u '${PYTHON_SCRIPT}'; \
"

rc=$?
echo "--- HOST: Job finished (container exited with code ${rc})."
exit $rc