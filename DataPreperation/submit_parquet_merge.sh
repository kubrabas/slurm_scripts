#!/bin/bash
#SBATCH --time=02:00:00
#SBATCH --account=def-nahee
#SBATCH --mem=32G
#SBATCH --cpus-per-task=4
#SBATCH --output=/home/kbas/scratch/slurm_parquet_merge_%j.out
#SBATCH --error=/home/kbas/scratch/slurm_parquet_merge_%j.out

# Runs automatically after the Parquet conversion job finishes (any outcome).
# Parameters come from submit_parquet.py via --export:
#   MC, FLAVOR, GEOMETRY, OUTDIR, LOGDIR

set -euo pipefail

mkdir -p "${LOGDIR}"

CONTAINER="/cvmfs/software.pacific-neutrino.org/containers/itray_v1.17.1"
BASEDIR="/usr/local/icetray"
GRAPHNET_SRC="/project/def-nahee/kbas/graphnet/src"
MERGE_SCRIPT="/project/def-nahee/kbas/Graphnet-Applications/DataPreperation/Parquet/merge_parquet.py"

echo "--- HOST: JOB=${SLURM_JOB_ID:-} HOST=$(hostname)"
echo "--- CONFIG: MC=${MC}  FLAVOR=${FLAVOR}  GEOMETRY=${GEOMETRY}"
echo "--- CONFIG: OUTDIR=${OUTDIR}"
echo "--- CONFIG: LOGDIR=${LOGDIR}"

module --force purge
module load StdEnv/2020 gcc/11.3.0 apptainer scipy-stack/2023b

unset I3_SHELL || true
unset I3_BUILD || true

apptainer exec   -B /localscratch/   -B /cvmfs/software.pacific-neutrino.org/   -B /home/kbas/scratch   "${CONTAINER}"   bash -lc "     set -euo pipefail;     export PATH=${BASEDIR}/build/bin:\${PATH};     export LD_LIBRARY_PATH=${BASEDIR}/build/lib:\${LD_LIBRARY_PATH:-};     export PYTHONPATH=${GRAPHNET_SRC}:/usr/local/lib:${BASEDIR}/build/lib:\${PYTHONPATH:-};     export I3_SRC=${BASEDIR};     export I3_BUILD=${BASEDIR}/build;     export PYTHONUNBUFFERED=1;     python3 -u '${MERGE_SCRIPT}'       --mc '${MC}'       --flavor '${FLAVOR}'       --geometry '${GEOMETRY}'       --outdir '${OUTDIR}'       --logdir '${LOGDIR}'       --num-workers 4   "

rc=$?
echo "--- merge finished (rc=${rc})"
exit $rc
