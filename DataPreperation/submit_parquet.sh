#!/bin/bash
#SBATCH --time=12:00:00
#SBATCH --account=def-nahee
#SBATCH --mem=64G
#SBATCH --cpus-per-task=16
#SBATCH --output=/home/kbas/scratch/slurm_parquet_%j.out
#SBATCH --error=/home/kbas/scratch/slurm_parquet_%j.out

# All parameters come from submit_parquet.py via --export:
#   MC, FLAVOR, GEOMETRY, INDIR, GCD, OUTDIR, LOGDIR, PULSEMAP, NWORKERS

set -euo pipefail

mkdir -p "${LOGDIR}"
mkdir -p "${OUTDIR}"

echo "--- HOST: JOB=${SLURM_JOB_ID:-} HOST=$(hostname) NWORKERS=${NWORKERS:-?}"

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
echo "--- CONFIG: NWORKERS=${NWORKERS}"

apptainer exec \
  -B /localscratch/ \
  -B /cvmfs/software.pacific-neutrino.org/ \
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
      --nworkers '${NWORKERS}' \
  "

rc=$?
echo "--- DEBUG (HOST): Job finished (rc=${rc})"
exit $rc
