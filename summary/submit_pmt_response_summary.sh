#!/bin/bash
#SBATCH --job-name=PMT_Summary
#SBATCH --time=48:00:00
#SBATCH --account=def-nahee
#SBATCH --mem=96G
#SBATCH --cpus-per-task=8
#SBATCH --output=/home/kbas/scratch/logs/summary_pmt_%j.out
#SBATCH --error=/home/kbas/scratch/logs/summary_pmt_%j.out

set -euo pipefail

OUTDIR="/project/def-nahee/kbas/Graphnet-Applications/Playground/Datasets"
LOGDIR="${OUTDIR}/logs"
mkdir -p "${LOGDIR}"
mkdir -p "${OUTDIR}"

echo "--- HOST: JOB=${SLURM_JOB_ID:-} HOST=$(hostname)"
echo "--- OUTDIR: ${OUTDIR}"
echo "--- CPUS_PER_TASK: ${SLURM_CPUS_PER_TASK:-unset}"

module load StdEnv/2020 gcc/11.3.0 apptainer scipy-stack/2023b

PONE_ENV_DIR="/project/def-nahee/kbas/pone_offline"
EXPORTS_FILE="${PONE_ENV_DIR}/icetray_exports.sh"

PYTHON_SCRIPT="/project/def-nahee/kbas/Graphnet-Applications/Playground/Datasets/prepare_summary_for_PMT_Responses.py"

IMG="/cvmfs/software.pacific-neutrino.org/containers/itray_v1.15.3"

unset I3_SHELL || true
unset I3_BUILD || true


apptainer exec \
  "${IMG}" \
  bash -lc " \
    set -euo pipefail; \
    if [ -f '${EXPORTS_FILE}' ]; then \
      source '${EXPORTS_FILE}'; \
    else \
      echo 'ERROR: exports file not found: ${EXPORTS_FILE}'; exit 2; \
    fi; \
    export PYTHONUNBUFFERED=1; \
    python3 -u '${PYTHON_SCRIPT}' \
      --workers ${SLURM_CPUS_PER_TASK:-1} \
      --progress-every 50 \
  "

rc=$?
echo "--- HOST: Job finished (container exited with code ${rc})."
exit $rc