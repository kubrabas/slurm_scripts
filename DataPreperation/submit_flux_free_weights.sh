#!/bin/bash
#SBATCH --time=06:00:00
#SBATCH --account=def-nahee
#SBATCH --mem=64G
#SBATCH --output=/home/kbas/SlurmScripts/Logs/flux_free_weights_%j.out
#SBATCH --error=/home/kbas/SlurmScripts/Logs/flux_free_weights_%j.out

# Parameters via --export:
#   MC_NAME

set -euo pipefail

echo "--- START: $(date)"
echo "--- HOST: JOB=${SLURM_JOB_ID:-} HOST=$(hostname)"
echo "--- CONFIG: MC_NAME=${MC_NAME}"

module --force purge
module load StdEnv/2020 gcc/11.3.0 apptainer scipy-stack/2023b

CONTAINER="/cvmfs/software.pacific-neutrino.org/containers/itray_v1.17.1"
BASEDIR="/usr/local/icetray"
PYTHON_SCRIPT="/project/def-nahee/kbas/Graphnet-Applications/DataPreperation/EventWeights/calculate_flux_free_weights.py"

unset I3_SHELL || true
unset I3_BUILD || true

mkdir -p /home/kbas/SlurmScripts/Logs

apptainer exec \
  -B /localscratch/ \
  -B /cvmfs/software.pacific-neutrino.org/ \
  -B /project/ \
  -B /home/kbas/ \
  "${CONTAINER}" \
  bash -lc " \
    set -euo pipefail; \
    export PATH=${BASEDIR}/build/bin:\${PATH}; \
    export LD_LIBRARY_PATH=${BASEDIR}/build/lib:\${LD_LIBRARY_PATH:-}; \
    export PYTHONPATH=/usr/local/lib:${BASEDIR}/build/lib:\${PYTHONPATH:-}; \
    export I3_SRC=${BASEDIR}; \
    export I3_BUILD=${BASEDIR}/build; \
    export PYTHONUNBUFFERED=1; \
    python3 -u '${PYTHON_SCRIPT}' \
      --mc_name '${MC_NAME}' \
  "

rc=$?
echo "--- END: $(date)"
echo "--- DEBUG: Job finished (rc=${rc})"
exit $rc