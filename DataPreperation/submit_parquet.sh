#!/bin/bash
#SBATCH --time=00:30:00
#SBATCH --account=def-nahee
#SBATCH --mem=16G
#SBATCH --cpus-per-task=2
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null

# All parameters come from submit_parquet.py via --export:
#   MC, FLAVOR, GEOMETRY, INDIR, GCD, OUTDIR, LOGDIR

set -euo pipefail

mkdir -p "${LOGDIR}"
mkdir -p "${OUTDIR}"

echo "--- HOST: ARRAY_JOB_ID=${SLURM_ARRAY_JOB_ID:-} TASK=${SLURM_ARRAY_TASK_ID:-} JOB=${SLURM_JOB_ID:-} HOST=$(hostname)"

module --force purge
module load StdEnv/2020 gcc/11.3.0 apptainer scipy-stack/2023b

CONTAINER="/cvmfs/software.pacific-neutrino.org/containers/itray_v1.17.1"
BASEDIR="/usr/local/icetray"
GRAPHNET_SRC="/project/def-nahee/kbas/graphnet/src"
PYTHON_SCRIPT="/project/def-nahee/kbas/Graphnet-Applications/DataPreperation/Parquet/convert_parquet.py"

unset I3_SHELL || true
unset I3_BUILD || true

echo "--- CONFIG: MC=${MC}"
echo "--- CONFIG: FLAVOR=${FLAVOR}"
echo "--- CONFIG: GEOMETRY=${GEOMETRY}"
echo "--- CONFIG: INDIR=${INDIR}"
echo "--- CONFIG: GCD=${GCD}"
echo "--- CONFIG: OUTDIR=${OUTDIR}"
echo "--- CONFIG: LOGDIR=${LOGDIR}"

apptainer exec \
  -B /localscratch/ \
  -B /cvmfs/software.pacific-neutrino.org/ \
  -B /project \
  -B /home/kbas/scratch \
  "${CONTAINER}" \
  bash -lc " \
    set -euo pipefail; \
    export PATH=${BASEDIR}/build/bin:\${PATH}; \
    export LD_LIBRARY_PATH=${BASEDIR}/build/lib:\${LD_LIBRARY_PATH:-}; \
    export PYTHONPATH=${GRAPHNET_SRC}:/usr/local/lib:${BASEDIR}/build/lib:\${PYTHONPATH:-}; \
    export I3_SRC=${BASEDIR}; \
    export I3_BUILD=${BASEDIR}/build; \
    export PYTHONUNBUFFERED=1; \
    python3 -u '${PYTHON_SCRIPT}' \
      --mc '${MC}' \
      --flavor '${FLAVOR}' \
      --geometry '${GEOMETRY}' \
      --indir '${INDIR}' \
      --gcd '${GCD}' \
      --outdir '${OUTDIR}' \
      --logdir '${LOGDIR}' \
      --pulsemap '${PULSEMAP}' \
  "

rc=$?
echo "--- DEBUG (HOST): Job finished (rc=${rc})"
exit $rc
