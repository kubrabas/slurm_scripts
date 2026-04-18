#!/bin/bash
#SBATCH --job-name=muon_pmt_response_large
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

mkdir -p /home/kbas/scratch/${sub_geometry}/logs/${flavor}_pmt_response
mkdir -p /home/kbas/scratch/${sub_geometry}/${flavor}_pmt_response

echo "--- HOST: ARRAY_JOB_ID=${SLURM_ARRAY_JOB_ID:-} TASK=${SLURM_ARRAY_TASK_ID:-} JOB=${SLURM_JOB_ID:-} HOST=$(hostname)"

module load StdEnv/2020 gcc/11.3.0 apptainer scipy-stack/2023b

PONE_ENV_DIR="/project/def-nahee/kbas/pone_offline"
PYTHON_SCRIPT="/project/def-nahee/kbas/Graphnet-Applications/DataPreperation/pmt_response.py"
EXPORTS_FILE="${PONE_ENV_DIR}/icetray_exports.sh"

unset I3_SHELL || true
unset I3_BUILD || true

echo "--- DEBUG (HOST): Before apptainer exec: I3_SHELL='${I3_SHELL:-}'"

SIM_PATH="/home/kbas/scratch/${sub_geometry}/${flavor}_I3Photons"
OUTDIR="/home/kbas/scratch/${sub_geometry}/${flavor}_pmt_response"
LOGDIR="/home/kbas/scratch/${sub_geometry}/logs/${flavor}_pmt_response"

GCD="/home/kbas/scratch/${sub_geometry}/GCD_${sub_geometry}.i3.gz"

task_id="${SLURM_ARRAY_TASK_ID:-}"
if [ -z "${task_id}" ]; then
  echo "ERROR: SLURM_ARRAY_TASK_ID is not set"
  exit 2
fi

mapfile -t files < <(find "${SIM_PATH}" -maxdepth 1 -type f \( -name "*.i3" -o -name "*.i3.gz" -o -name "*.i3.zst" \) | sort)

if [ "${#files[@]}" -eq 0 ]; then
  echo "ERROR: No files found in ${SIM_PATH}"
  exit 3
fi

if [ "${task_id}" -lt 0 ] || [ "${task_id}" -ge "${#files[@]}" ]; then
  echo "ERROR: task_id=${task_id} out of range (0..$((${#files[@]} - 1))), inputs=${#files[@]}"
  exit 4
fi

infile="${files[$task_id]}"
input_base="$(basename "${infile}")"
input_base="${input_base%.i3.gz}"
input_base="${input_base%.i3}"
input_base="${input_base%.zst}"
input_base="${input_base%_skim}"

LOGFILE="${LOGDIR}/${input_base}_${SLURM_ARRAY_JOB_ID:-unknown}_${SLURM_ARRAY_TASK_ID:-unknown}_${SLURM_JOB_ID:-unknown}.out"

echo "--- CONFIG: flavor=${flavor}"
echo "--- CONFIG: sub_geometry=${sub_geometry}"
echo "--- CONFIG: pone_env_dir=${PONE_ENV_DIR}"
echo "--- CONFIG: python_script=${PYTHON_SCRIPT}"
echo "--- CONFIG: sim_path=${SIM_PATH}"
echo "--- CONFIG: outdir=${OUTDIR}"
echo "--- CONFIG: gcd=${GCD}"
echo "--- CONFIG: infile=${infile}"
echo "--- CONFIG: logfile=${LOGFILE}"

{
  echo "--- HOST: ARRAY_JOB_ID=${SLURM_ARRAY_JOB_ID:-} TASK=${SLURM_ARRAY_TASK_ID:-} JOB=${SLURM_JOB_ID:-} HOST=$(hostname)"
  echo "--- CONFIG: flavor=${flavor}"
  echo "--- CONFIG: sub_geometry=${sub_geometry}"
  echo "--- CONFIG: pone_env_dir=${PONE_ENV_DIR}"
  echo "--- CONFIG: python_script=${PYTHON_SCRIPT}"
  echo "--- CONFIG: sim_path=${SIM_PATH}"
  echo "--- CONFIG: outdir=${OUTDIR}"
  echo "--- CONFIG: gcd=${GCD}"
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
      export PONE_ENV_DIR='${PONE_ENV_DIR}'; \
      export FLAVOR='${flavor}'; \
      export SUB_GEOMETRY='${sub_geometry}'; \
      export SIM_PATH='${SIM_PATH}'; \
      export OUTPUT_FOLDER='${OUTDIR}'; \
      export GCD_FILE='${GCD}'; \
      echo '--- DEBUG (CONTAINER): I3_SHELL=' \$I3_SHELL; \
      env | egrep 'I3_|PYTHONPATH|LD_LIBRARY_PATH|PONE_ENV_DIR|FLAVOR|SUB_GEOMETRY|SIM_PATH|OUTPUT_FOLDER|GCD_FILE' || true; \
      echo '--- CONFIG (CONTAINER): flavor=${flavor}'; \
      echo '--- CONFIG (CONTAINER): sub_geometry=${sub_geometry}'; \
      echo '--- CONFIG (CONTAINER): pone_env_dir=${PONE_ENV_DIR}'; \
      echo '--- CONFIG (CONTAINER): python_script=${PYTHON_SCRIPT}'; \
      echo '--- CONFIG (CONTAINER): sim_path=${SIM_PATH}'; \
      echo '--- CONFIG (CONTAINER): outdir=${OUTDIR}'; \
      echo '--- CONFIG (CONTAINER): gcd=${GCD}'; \
      echo '--- CONFIG (CONTAINER): infile=${infile}'; \
      echo '--- DEBUG (CONTAINER): Running python'; \
      python3 '${PYTHON_SCRIPT}' --infile '${infile}' \
    "
  rc=$?
  echo "--- DEBUG (HOST): Job finished (container exited with code ${rc})."
  exit $rc
} 2>&1 | tee "${LOGFILE}"

rc=${PIPESTATUS[0]}
exit $rc