#!/bin/bash
#SBATCH --time=03:00:00
#SBATCH --account=def-nahee
#SBATCH --mem=32G
#SBATCH --cpus-per-task=1
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null

# All parameters come from submit_pmt_response.py via --export:
#   FLAVOR, GEOMETRY, MC, INDIR, PATTERN, GCD, OUTDIR, LOGDIR

set -euo pipefail

mkdir -p "${LOGDIR}"
mkdir -p "${OUTDIR}"

echo "--- HOST: ARRAY_JOB_ID=${SLURM_ARRAY_JOB_ID:-} TASK=${SLURM_ARRAY_TASK_ID:-} JOB=${SLURM_JOB_ID:-} HOST=$(hostname)"

module --force purge
module load StdEnv/2020 gcc/11.3.0 apptainer scipy-stack/2023b

CONTAINER="/cvmfs/software.pacific-neutrino.org/containers/itray_v1.17.1"
PONE_OFFLINE="/cvmfs/software.pacific-neutrino.org/pone_offline/v1.2"
PONESRCDIR="/project/6008051/pone_simulation/pone_offline"
BASEDIR="/usr/local/icetray"
PMT_BASE="/project/def-nahee/kbas/Graphnet-Applications/DataPreperation/PmtResponse"
if [[ "${WITH_FIRST_3_LAYERS:-0}" == "1" ]]; then
    PYTHON_SCRIPT="${PMT_BASE}/apply_pmt_response_with_first_3_layers.py"
else
    PYTHON_SCRIPT="${PMT_BASE}/apply_pmt_response_without_first_3_layers.py"
fi

unset I3_SHELL || true
unset I3_BUILD || true

echo "--- CONFIG: MC=${MC}"
echo "--- CONFIG: FLAVOR=${FLAVOR}"
echo "--- CONFIG: GEOMETRY=${GEOMETRY}"
echo "--- CONFIG: INDIR=${INDIR}"
echo "--- CONFIG: PATTERN=${PATTERN}"
echo "--- CONFIG: GCD=${GCD}"
echo "--- CONFIG: OUTDIR=${OUTDIR}"
echo "--- CONFIG: LOGDIR=${LOGDIR}"
echo "--- CONFIG: PYTHON_SCRIPT=${PYTHON_SCRIPT}"

apptainer exec \
  -B /localscratch/ \
  -B /cvmfs/software.pacific-neutrino.org/ \
  "${CONTAINER}" \
  bash -c " \
    set -euo pipefail; \
    export PATH=${BASEDIR}/build/bin:\${PATH}; \
    export LD_LIBRARY_PATH=${BASEDIR}/build/lib:\${LD_LIBRARY_PATH:-}; \
    export PYTHONPATH=/usr/local/lib:${BASEDIR}/build/lib:${PONE_OFFLINE}:\${PYTHONPATH:-}; \
    export I3_SRC=${BASEDIR}; \
    export I3_BUILD=${BASEDIR}/build; \
    export PONESRCDIR='${PONESRCDIR}'; \
    export PYTHONUNBUFFERED=1; \
    python3 -u '${PYTHON_SCRIPT}' \
      --flavor '${FLAVOR}' \
      --geometry '${GEOMETRY}' \
      --mc '${MC}' \
      --indir '${INDIR}' \
      --pattern '${PATTERN}' \
      --outdir '${OUTDIR}' \
      --logdir '${LOGDIR}' \
      --gcd '${GCD}' \
  "

rc=$?
echo "--- DEBUG (HOST): Job finished (rc=${rc})"
exit $rc
