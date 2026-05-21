#!/bin/bash
#SBATCH --time=06:00:00
#SBATCH --account=def-nahee
#SBATCH --mem=64G
#SBATCH --cpus-per-task=8

set -euo pipefail

SCRIPT_PATH="$(readlink -f "$0")"

usage() {
  cat <<EOF
Usage:
  $0 --mc-name STRING340MC --geometry full_geometry [--workers 8]

Options:
  --mc-name       SPRING2026MC or STRING340MC (default: SPRING2026MC)
  --geometry      Geometry key from Metadata/paths.py (default: full_geometry)
  --pulsemap-key  Pulse map key to count (default: Accepted_PulseMap)
  --out-csv       Optional output CSV path
  --workers       Parallel file workers inside the job (default: 8)
  --time          SLURM time, e.g. 06:00:00 (default: 06:00:00)
  --mem           SLURM memory, e.g. 64G (default: 64G)
  --dry-run       Print sbatch command without submitting
EOF
}

if [[ -z "${SLURM_JOB_ID:-}" ]]; then
  MC_NAME="SPRING2026MC"
  GEOMETRY="full_geometry"
  PULSEMAP_KEY="Accepted_PulseMap"
  OUT_CSV=""
  WORKERS="8"
  TIME_LIMIT="06:00:00"
  MEMORY="64G"
  DRY_RUN="0"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --mc-name|-m) MC_NAME="$2"; shift 2 ;;
      --geometry|-g) GEOMETRY="$2"; shift 2 ;;
      --pulsemap-key) PULSEMAP_KEY="$2"; shift 2 ;;
      --out-csv) OUT_CSV="$2"; shift 2 ;;
      --workers|-w) WORKERS="$2"; shift 2 ;;
      --time) TIME_LIMIT="$2"; shift 2 ;;
      --mem) MEMORY="$2"; shift 2 ;;
      --dry-run) DRY_RUN="1"; shift ;;
      --help|-h) usage; exit 0 ;;
      *) echo "Unknown argument: $1" >&2; usage; exit 2 ;;
    esac
  done

  case "${MC_NAME}" in
    SPRING2026MC) MC_FOLDER="Spring2026MC" ;;
    STRING340MC) MC_FOLDER="String340MC" ;;
    *) MC_FOLDER="${MC_NAME}" ;;
  esac
  JOB_DATE="$(date +%d_%m_%Y)"
  LOG_DIR="/home/kbas/scratch/${MC_FOLDER}/Logs/EventStatistics"
  if [[ "${DRY_RUN}" != "1" ]]; then
    mkdir -p "${LOG_DIR}"
  fi
  JOB_NAME="eventstats_${MC_NAME}_${GEOMETRY}"
  LOG_FILE="${LOG_DIR}/%j_${JOB_DATE}_${GEOMETRY}_eventstats.out"

  CMD=(
    sbatch
    "--job-name=${JOB_NAME}"
    "--time=${TIME_LIMIT}"
    "--mem=${MEMORY}"
    "--cpus-per-task=${WORKERS}"
    "--output=${LOG_FILE}"
    "--error=${LOG_FILE}"
    "--export=ALL,MC_NAME=${MC_NAME},GEOMETRY=${GEOMETRY},PULSEMAP_KEY=${PULSEMAP_KEY},OUT_CSV=${OUT_CSV},WORKERS=${WORKERS},JOB_DATE=${JOB_DATE}"
    "${SCRIPT_PATH}"
  )

  if [[ "${DRY_RUN}" == "1" ]]; then
    echo "[DRY-RUN] submitting: ${JOB_NAME}"
  else
    echo "submitting: ${JOB_NAME}"
  fi
  echo "  mc_name      : ${MC_NAME}"
  echo "  geometry     : ${GEOMETRY}"
  echo "  pulsemap_key : ${PULSEMAP_KEY}"
  echo "  workers      : ${WORKERS}"
  echo "  out_csv      : ${OUT_CSV:-default}"
  echo "  log_file     : ${LOG_FILE}"

  if [[ "${DRY_RUN}" == "1" ]]; then
    printf '  cmd:'
    printf ' %q' "${CMD[@]}"
    printf '\n'
    exit 0
  fi

  "${CMD[@]}"
  exit 0
fi

module --force purge
module load StdEnv/2020 gcc/11.3.0 apptainer scipy-stack/2023b

CONTAINER="/cvmfs/software.pacific-neutrino.org/containers/itray_v1.17.1"
PONE_OFFLINE="/cvmfs/software.pacific-neutrino.org/pone_offline/v2.0"
PONESRCDIR="/project/6008051/pone_simulation/pone_offline"
BASEDIR="/usr/local/icetray"
PYTHON_SCRIPT="/project/def-nahee/kbas/Graphnet-Applications/DataPreperation/DatasetStatistics/build_event_statistics.py"

unset I3_SHELL || true
unset I3_BUILD || true

echo "--- HOST: JOB=${SLURM_JOB_ID:-} HOST=$(hostname)"
echo "--- CONFIG: MC_NAME=${MC_NAME}"
echo "--- CONFIG: GEOMETRY=${GEOMETRY}"
echo "--- CONFIG: PULSEMAP_KEY=${PULSEMAP_KEY}"
echo "--- CONFIG: OUT_CSV=${OUT_CSV:-default}"
echo "--- CONFIG: WORKERS=${WORKERS}"
echo "--- CONFIG: PYTHON_SCRIPT=${PYTHON_SCRIPT}"

case "${MC_NAME}" in
  SPRING2026MC) MC_FOLDER="Spring2026MC" ;;
  STRING340MC) MC_FOLDER="String340MC" ;;
  *) MC_FOLDER="${MC_NAME}" ;;
esac
case "${MC_NAME}" in
  SPRING2026MC) METADATA_MC_FOLDER="Spring2026MC" ;;
  STRING340MC) METADATA_MC_FOLDER="String340MC" ;;
  *) METADATA_MC_FOLDER="${MC_NAME}" ;;
esac
OUT_DIR="/project/def-nahee/kbas/Graphnet-Applications/Metadata/DatasetStatistics/${METADATA_MC_FOLDER}/${GEOMETRY}"
mkdir -p "${OUT_DIR}"
if [[ -z "${OUT_CSV:-}" ]]; then
  OUT_CSV="${OUT_DIR}/event_statistics_${JOB_DATE:-$(date +%d_%m_%Y)}.csv"
fi
mkdir -p "$(dirname "${OUT_CSV}")"
echo "--- CONFIG: FINAL_OUT_CSV=${OUT_CSV}"

apptainer exec \
  -B /localscratch/ \
  -B /cvmfs/software.pacific-neutrino.org/ \
  "${CONTAINER}" \
  bash -lc " \
    set -euo pipefail; \
    export PATH=${BASEDIR}/build/bin:\${PATH}; \
    export LD_LIBRARY_PATH=${BASEDIR}/build/lib:\${LD_LIBRARY_PATH:-}; \
    export PYTHONPATH=/usr/local/lib:${BASEDIR}/build/lib:${PONE_OFFLINE}:\${PYTHONPATH:-}; \
    export I3_SRC=${BASEDIR}; \
    export I3_BUILD=${BASEDIR}/build; \
    export PONESRCDIR='${PONESRCDIR}'; \
    export PYTHONUNBUFFERED=1; \
    python3 -u '${PYTHON_SCRIPT}' \
      --mc-name '${MC_NAME}' \
      --geometry '${GEOMETRY}' \
      --pulsemap-key '${PULSEMAP_KEY}' \
      --workers '${WORKERS}' \
      ${OUT_CSV:+--out-csv '${OUT_CSV}'} \
  "

rc=$?
echo "--- DEBUG (HOST): Job finished (rc=${rc})"
exit "${rc}"
