#!/bin/bash
#SBATCH --job-name=Muon_102_PMT_Response_Serial
#SBATCH --time=01:00:00
#SBATCH --account=def-nahee
#SBATCH --array=0-9818%50
#SBATCH --mem=16G
#SBATCH --cpus-per-task=1
#SBATCH --output=/home/kbas/scratch/102_string/logs/Muon_response/_%A_%a.out
#SBATCH --error=/home/kbas/scratch/102_string/logs/Muon_response/_%A_%a.out

set -euo pipefail
mkdir -p /home/kbas/scratch/102_string/logs/Muon_response

echo "--- HOST: JOB=${SLURM_JOB_ID:-} TASK=${SLURM_ARRAY_TASK_ID:-}"

module load StdEnv/2020 gcc/11.3.0 apptainer scipy-stack/2023b

PONE_ENV_DIR="/project/def-nahee/kbas/pone_offline"
PYTHON_SCRIPT="/project/def-nahee/kbas/pone_offline/apply_POM_response_serial_102_string_muon.py"
EXPORTS_FILE="${PONE_ENV_DIR}/icetray_exports.sh"

unset I3_SHELL || true
unset I3_BUILD || true

echo "--- DEBUG (HOST): Before apptainer exec: I3_SHELL='${I3_SHELL:-}'"

apptainer exec /cvmfs/software.pacific-neutrino.org/containers/itray_v1.15.3 \
    bash -cx " \
      set -euo pipefail; \
      cd '${PONE_ENV_DIR}'; \
      if [ -f '${EXPORTS_FILE}' ]; then \
         echo '--- DEBUG (CONTAINER): Sourcing exports file: ${EXPORTS_FILE}'; \
         source '${EXPORTS_FILE}'; \
      else \
         echo 'ERROR: exports file not found: ${EXPORTS_FILE}'; exit 2; \
      fi; \
      echo '--- DEBUG (CONTAINER): I3_SHELL=' \$I3_SHELL; \
      env | egrep 'I3_|PYTHONPATH|LD_LIBRARY_PATH' || true; \
      echo '--- DEBUG (CONTAINER): Running python'; \
      python3 '${PYTHON_SCRIPT}' \
    "
rc=$?
echo "--- DEBUG (HOST): Job finished (container exited with code ${rc})."
exit $rc
