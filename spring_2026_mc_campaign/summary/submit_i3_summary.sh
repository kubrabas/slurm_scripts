#!/bin/bash
#SBATCH --job-name=I3Photons_Summary
#SBATCH --time=48:00:00
#SBATCH --account=def-nahee
#SBATCH --mem=96G
#SBATCH --cpus-per-task=8
#SBATCH --output=/home/kbas/scratch/2026_Spring_MC/logs/summary_i3_%j.out
#SBATCH --error=/home/kbas/scratch/2026_Spring_MC/logs/summary_i3_%j.out

set -euo pipefail

OUTDIR="/project/def-nahee/kbas/Graphnet-Applications/Playground/2026_Spring_MC/Datasets"
LOGDIR="/home/kbas/scratch/2026_Spring_MC/logs"
mkdir -p "${LOGDIR}"
mkdir -p "${OUTDIR}"

echo "--- HOST: JOB=${SLURM_JOB_ID:-} HOST=$(hostname)"
echo "--- OUTDIR: ${OUTDIR}"
echo "--- CPUS_PER_TASK: ${SLURM_CPUS_PER_TASK:-unset}"

module --force-purge
module load StdEnv/2020 gcc/11.3.0 apptainer scipy-stack/2023b

CONTAINER="/cvmfs/software.pacific-neutrino.org/containers/itray_v1.17.1"
PONE_OFFLINE="/cvmfs/software.pacific-neutrino.org/pone_offline/v1.2"
PONESRCDIR="/project/6008051/pone_simulation/pone_offline"

PYTHON_SCRIPT="/project/def-nahee/kbas/Graphnet-Applications/Playground/2026_Spring_MC/Datasets/prepare_summary_for_I3.py"

unset I3_SHELL || true
unset I3_BUILD || true

apptainer exec \
  -B /usr/local/scratch/ \
  -B /cvmfs/software.pacific-neutrino.org/ \
  -B /etc/OpenCL \
  --nv \
  "${CONTAINER}" \
  bash -lc " \
    set -euo pipefail; \
    export PYTHONPATH='${PONE_OFFLINE}:\${PYTHONPATH:-}'; \
    export PONESRCDIR='${PONESRCDIR}'; \
    export PYTHONUNBUFFERED=1; \
    python3 -u '${PYTHON_SCRIPT}' \
      --workers ${SLURM_CPUS_PER_TASK:-1} \
  "

rc=$?
echo "--- HOST: Job finished (container exited with code ${rc})."
exit $rc


not finished and checked