#!/bin/bash
#SBATCH --time=06:00:00
#SBATCH --account=def-nahee
#SBATCH --mem=64G
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null

# All parameters come from submit_summary_for_I3.py via --export:
#   MC_NAME, PHOTON_KEY, OUT_CSV, OUT_TXT, WORKERS

set -euo pipefail

echo "--- HOST: JOB=${SLURM_JOB_ID:-} HOST=$(hostname)"

module --force purge
module load StdEnv/2020 gcc/11.3.0 apptainer scipy-stack/2023b

CONTAINER="/cvmfs/software.pacific-neutrino.org/containers/itray_v1.17.1"
PONE_OFFLINE="/cvmfs/software.pacific-neutrino.org/pone_offline/v1.2"
PONESRCDIR="/project/6008051/pone_simulation/pone_offline"
BASEDIR="/usr/local/icetray"
PYTHON_SCRIPT="/project/def-nahee/kbas/Graphnet-Applications/DataPreperation/DatasetStatistics/prepare_summary_for_I3.py"

unset I3_SHELL || true
unset I3_BUILD || true

echo "--- CONFIG: MC_NAME=${MC_NAME}"
echo "--- CONFIG: PHOTON_KEY=${PHOTON_KEY}"
echo "--- CONFIG: OUT_CSV=${OUT_CSV}"
echo "--- CONFIG: OUT_TXT=${OUT_TXT}"
echo "--- CONFIG: WORKERS=${WORKERS}"

mkdir -p "$(dirname "${OUT_CSV}")"
mkdir -p "$(dirname "${OUT_TXT}")"

apptainer exec \
  -B /localscratch/ \
  -B /cvmfs/software.pacific-neutrino.org/ \
  "${CONTAINER}" \
  bash -lc " \
    set -euo pipefail; \
    export PATH=${BASEDIR}/build/bin:\${PATH}; \
    export LD_LIBRARY_PATH=${BASEDIR}/build/lib:\${LD_LIBRARY_PATH:-}; \
    export PYTHONPATH=/usr/local/lib:${BASEDIR}/build/lib:${PONE_OFFLINE}:\${PYTHONPATH:-}; \
    export I3_SRC=${BASEDIR}; \
    export I3_BUILD=${BASEDIR}/build; \
    export PONESRCDIR='${PONESRCDIR}'; \
    export PYTHONUNBUFFERED=1; \
    python3 -u '${PYTHON_SCRIPT}' \
      --mc-name '${MC_NAME}' \
      --photon-key '${PHOTON_KEY}' \
      --out-csv '${OUT_CSV}' \
      --out-txt '${OUT_TXT}' \
      --workers '${WORKERS}' \
  "

rc=$?
echo "--- DEBUG (HOST): Job finished (rc=${rc})"
exit $rc
