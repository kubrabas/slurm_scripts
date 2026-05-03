#!/bin/bash
#SBATCH --time=00:05:00
#SBATCH --account=def-nahee
#SBATCH --mem=16G
#SBATCH --cpus-per-task=1
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null

# All parameters come from submit_LIW.py via --export:
#   MC, FLAVOR, LIC_DIR, PHOTON_DIR, PHOTON_PATTERN, OUTDIR, LOGDIR

set -euo pipefail

mkdir -p "${LOGDIR}"
mkdir -p "${OUTDIR}"

echo "--- HOST: ARRAY_JOB_ID=${SLURM_ARRAY_JOB_ID:-} TASK=${SLURM_ARRAY_TASK_ID:-} JOB=${SLURM_JOB_ID:-} HOST=$(hostname)"

module --force purge
module load StdEnv/2020 gcc/11.3.0 apptainer scipy-stack/2023b

CONTAINER="/cvmfs/software.pacific-neutrino.org/containers/itray_v1.17.1"
PONE_OFFLINE="/cvmfs/software.pacific-neutrino.org/pone_offline/v2.0"
PONESRCDIR="/project/6008051/pone_simulation/pone_offline"
BASEDIR="/usr/local/icetray"
PYTHON_SCRIPT="/project/def-nahee/kbas/Graphnet-Applications/DataPreperation/EventWeights/LIW/calculate_LIW.py"

unset I3_SHELL || true
unset I3_BUILD || true

echo "--- CONFIG: MC=${MC}"
echo "--- CONFIG: FLAVOR=${FLAVOR}"
echo "--- CONFIG: LIC_DIR=${LIC_DIR}"
echo "--- CONFIG: PHOTON_DIR=${PHOTON_DIR}"
echo "--- CONFIG: PHOTON_PATTERN=${PHOTON_PATTERN}"
echo "--- CONFIG: OUTDIR=${OUTDIR}"
echo "--- CONFIG: LOGDIR=${LOGDIR}"

apptainer exec \
  -B /localscratch/ \
  -B /cvmfs/software.pacific-neutrino.org/ \
  "${CONTAINER}" \
  bash -lc " \
    set -euo pipefail; \
    export PATH=${BASEDIR}/build/bin:\${PATH}; \
    export LD_LIBRARY_PATH=/usr/local/LeptonWeighter/lib:/usr/local/lib:${BASEDIR}/build/lib:\${LD_LIBRARY_PATH:-}; \
    export PYTHONPATH=/usr/local/LeptonWeighter/lib:/usr/local/lib:${BASEDIR}/build/lib:${PONE_OFFLINE}:\${PYTHONPATH:-}; \
    export I3_SRC=${BASEDIR}; \
    export I3_BUILD=${BASEDIR}/build; \
    export PONESRCDIR='${PONESRCDIR}'; \
    export PYTHONUNBUFFERED=1; \
    python3 -u '${PYTHON_SCRIPT}' \
      --mc '${MC}' \
      --flavor '${FLAVOR}' \
      --lic-dir '${LIC_DIR}' \
      --photon-dir '${PHOTON_DIR}' \
      --photon-pattern '${PHOTON_PATTERN}' \
      --outdir '${OUTDIR}' \
      --logdir '${LOGDIR}' \
  "

rc=$?
echo "--- DEBUG (HOST): Job finished (rc=${rc})"
exit $rc
