#!/bin/bash
#SBATCH --job-name=I3PhotonsSummarySpring2026MC
#SBATCH --time=48:00:00
#SBATCH --account=rpp-nahee
#SBATCH --mem=96G
#SBATCH --cpus-per-task=8
#SBATCH --output=/home/kbas/scratch/Spring2026MC/Logs/SummaryI3_i3_%j.out
#SBATCH --error=/home/kbas/scratch/Spring2026MC/Logs/SummaryI3_i3_%j.out

set -euo pipefail

MC_NAME="SPRING2026MC"

OUTDIR="/project/def-nahee/kbas/Graphnet-Applications/Metadata/DatasetStatistics/Spring2026MC"
LOGDIR="/home/kbas/scratch/Spring2026MC/Logs"
mkdir -p "${LOGDIR}"
mkdir -p "${OUTDIR}"

echo "--- HOST: JOB=${SLURM_JOB_ID:-} HOST=$(hostname)"
echo "--- MC_NAME: ${MC_NAME}"
echo "--- OUTDIR: ${OUTDIR}"
echo "--- CPUS_PER_TASK: ${SLURM_CPUS_PER_TASK:-unset}"

module --force purge
module load StdEnv/2020 gcc/11.3.0 apptainer scipy-stack/2023b

CONTAINER="/cvmfs/software.pacific-neutrino.org/containers/itray_v1.17.1"
PONE_OFFLINE="/cvmfs/software.pacific-neutrino.org/pone_offline/v1.2"
PONESRCDIR="/project/6008051/pone_simulation/pone_offline"

PYTHON_SCRIPT="/project/def-nahee/kbas/Graphnet-Applications/DataPreperation/DatasetStatistics/prepare_summary_for_I3.py"

unset I3_SHELL || true
unset I3_BUILD || true

apptainer exec \
  -B /localscratch/ \
  -B /cvmfs/software.pacific-neutrino.org/ \
  -B /etc/OpenCL \
  "${CONTAINER}" \
  bash -lc " \
    set -euo pipefail; \
    export PYTHONPATH='${PONE_OFFLINE}:\${PYTHONPATH:-}'; \
    export PONESRCDIR='${PONESRCDIR}'; \
    export PYTHONUNBUFFERED=1; \
    python3 -u '${PYTHON_SCRIPT}' \
      --mc-name '${MC_NAME}' \
      --workers '${SLURM_CPUS_PER_TASK:-1}' \
      --out-csv '${OUTDIR}/i3summary.csv' \
      --out-txt '${OUTDIR}/i3summary.txt' \
  "

rc=$?
echo "--- Job finished (rc=${rc})"
exit $rc