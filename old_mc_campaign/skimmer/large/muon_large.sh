#!/bin/bash
#SBATCH --job-name=muon_skim_large_from_340
#SBATCH --time=02:00:00
#SBATCH --account=def-nahee
#SBATCH --array=0-9818%50
#SBATCH --mem=32G
#SBATCH --cpus-per-task=1
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null

set -euo pipefail

flavor="muon"
sub_geometry="large"

mkdir -p /home/kbas/scratch/${sub_geometry}/logs/${flavor}_skim
mkdir -p /home/kbas/scratch/${sub_geometry}/${flavor}_I3Photons

echo "--- HOST: ARRAY_JOB_ID=${SLURM_ARRAY_JOB_ID:-} TASK=${SLURM_ARRAY_TASK_ID:-} JOB=${SLURM_JOB_ID:-} HOST=$(hostname)"

module load StdEnv/2020 gcc/11.3.0 apptainer scipy-stack/2023b

PONE_ENV_DIR="/project/def-nahee/kbas/pone_offline"
EXPORTS_FILE="${PONE_ENV_DIR}/icetray_exports.sh"

unset I3_SHELL || true
unset I3_BUILD || true
echo "--- DEBUG (HOST): Before apptainer exec: I3_SHELL='${I3_SHELL:-}'"

PYTHON_SCRIPT="/project/def-nahee/kbas/Graphnet-Applications/DataPreperation/trim_I3.py"

GCD="/project/6008051/pone_simulation/GCD_Library/PONE_800mGrid.i3.gz"
SELECTION="/project/def-nahee/kbas/Graphnet-Applications/DataPreperation/sub_geometries/${sub_geometry}.csv"
FILTERFRAME="/project/def-nahee/kbas/GeometrySkimmer/FilterFrame.py"

OUTDIR="/home/kbas/scratch/${sub_geometry}/${flavor}_I3Photons"
LOGDIR="/home/kbas/scratch/${sub_geometry}/logs/${flavor}_skim"

# Determine input pattern/indir exactly like the python defaults
if [ "${flavor}" = "electron" ]; then
  pattern="*.i3.zst"
  indir="/project/6008051/pone_simulation/MC000003-nu_e-2_7-LeptonInjector_PROPOSAL_clsim-v10/Generator"
elif [ "${flavor}" = "muon" ]; then
  pattern="*.i3"
  indir="/project/6008051/pone_simulation/MC10-000002-nu_mu-2_7-LeptonInjector-PROPOSAL-clsim/Photon"
elif [ "${flavor}" = "tau" ]; then
  pattern="*.i3.zst"
  indir="/project/6008051/pone_simulation/MC000004-nu_tau-2_7-LeptonInjector_PROPOSAL_clsim-v10/Generator"
else
  echo "ERROR: unknown flavor='${flavor}'"
  exit 2
fi

task_id="${SLURM_ARRAY_TASK_ID:-}"
if [ -z "${task_id}" ]; then
  echo "ERROR: SLURM_ARRAY_TASK_ID is not set"
  exit 2
fi

mapfile -t files < <(find "${indir}" -maxdepth 1 -type f -name "${pattern}" | sort)

if [ "${#files[@]}" -eq 0 ]; then
  echo "ERROR: No files found in ${indir} matching ${pattern}"
  exit 3
fi

if [ "${task_id}" -lt 0 ] || [ "${task_id}" -ge "${#files[@]}" ]; then
  echo "ERROR: task_id=${task_id} out of range (0..$((${#files[@]} - 1))), inputs=${#files[@]}"
  exit 4
fi

infile="${files[$task_id]}"
input_base="$(basename "${infile}")"
input_base="${input_base%.i3.zst}"
input_base="${input_base%.i3}"

LOGFILE="${LOGDIR}/${input_base}_${SLURM_ARRAY_JOB_ID:-unknown}_${SLURM_ARRAY_TASK_ID:-unknown}_${SLURM_JOB_ID:-unknown}.out"

echo "--- CONFIG: flavor=${flavor}"
echo "--- CONFIG: sub_geometry=${sub_geometry}"
echo "--- CONFIG: gcd=${GCD}"
echo "--- CONFIG: selection=${SELECTION}"
echo "--- CONFIG: outdir=${OUTDIR}"
echo "--- CONFIG: python_script=${PYTHON_SCRIPT}"
echo "--- CONFIG: filterframe=${FILTERFRAME}"
echo "--- CONFIG: indir=${indir}"
echo "--- CONFIG: pattern=${pattern}"
echo "--- CONFIG: infile=${infile}"
echo "--- CONFIG: logfile=${LOGFILE}"

{
  echo "--- HOST: ARRAY_JOB_ID=${SLURM_ARRAY_JOB_ID:-} TASK=${SLURM_ARRAY_TASK_ID:-} JOB=${SLURM_JOB_ID:-} HOST=$(hostname)"
  echo "--- CONFIG: flavor=${flavor}"
  echo "--- CONFIG: sub_geometry=${sub_geometry}"
  echo "--- CONFIG: gcd=${GCD}"
  echo "--- CONFIG: selection=${SELECTION}"
  echo "--- CONFIG: outdir=${OUTDIR}"
  echo "--- CONFIG: python_script=${PYTHON_SCRIPT}"
  echo "--- CONFIG: filterframe=${FILTERFRAME}"
  echo "--- CONFIG: indir=${indir}"
  echo "--- CONFIG: pattern=${pattern}"
  echo "--- CONFIG: infile=${infile}"
  echo "--- CONFIG: logfile=${LOGFILE}"

  apptainer exec /cvmfs/software.pacific-neutrino.org/containers/itray_v1.15.3 \
    bash -cx " \
      set -euo pipefail; \
      cd '${PONE_ENV_DIR}'; \
      if [ -f '${EXPORTS_FILE}' ]; then \
        echo '--- DEBUG (CONTAINER): Sourcing exports file: ${EXPORTS_FILE}'; \
        source '${EXPORTS_FILE}'; \
      else \
        echo 'ERROR: exports file not found: ${EXPORTS_FILE}'; exit 2; \
      fi; \
      echo '--- DEBUG (CONTAINER): I3_SHELL=' \$I3_SHELL; \
      env | egrep 'I3_|PYTHONPATH|LD_LIBRARY_PATH' || true; \
      echo '--- CONFIG (CONTAINER): flavor=${flavor}'; \
      echo '--- CONFIG (CONTAINER): sub_geometry=${sub_geometry}'; \
      echo '--- CONFIG (CONTAINER): gcd=${GCD}'; \
      echo '--- CONFIG (CONTAINER): selection=${SELECTION}'; \
      echo '--- CONFIG (CONTAINER): outdir=${OUTDIR}'; \
      echo '--- CONFIG (CONTAINER): python_script=${PYTHON_SCRIPT}'; \
      echo '--- CONFIG (CONTAINER): filterframe=${FILTERFRAME}'; \
      echo '--- CONFIG (CONTAINER): indir=${indir}'; \
      echo '--- CONFIG (CONTAINER): pattern=${pattern}'; \
      echo '--- CONFIG (CONTAINER): infile=${infile}'; \
      echo '--- DEBUG (CONTAINER): Running python'; \
      python3 '${PYTHON_SCRIPT}' \
        --particle '${flavor}' \
        --indir '${indir}' \
        --pattern '${pattern}' \
        --task-id '${task_id}' \
        --sub-geometry '${sub_geometry}' \
        --outdir '${OUTDIR}' \
        --gcd '${GCD}' \
        --selection '${SELECTION}' \
        --filterframe '${FILTERFRAME}' \
    "
  rc=$?
  echo "--- DEBUG (HOST): Job finished (container exited with code ${rc})."
  exit $rc
} 2>&1 | tee "${LOGFILE}"

rc=${PIPESTATUS[0]}
exit $rc