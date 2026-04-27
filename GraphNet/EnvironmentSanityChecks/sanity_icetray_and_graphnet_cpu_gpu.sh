#!/bin/bash
#SBATCH --job-name=sanity_icetray_and_graphnet_cpu_gpu
#SBATCH --account=def-nahee
#SBATCH --time=00:40:00
#SBATCH --mem=16G
#SBATCH --gpus-per-node=nvidia_h100_80gb_hbm3_1g.10gb:1
#SBATCH --cpus-per-task=2
#SBATCH --output=/home/kbas/SlurmScripts/GraphNet/EnvironmentSanityChecks/Logs/%x_%j.out
#SBATCH --error=/home/kbas/SlurmScripts/GraphNet/EnvironmentSanityChecks/Logs/%x_%j.out

module --force purge
module load StdEnv/2020 gcc/11.3.0 apptainer scipy-stack/2023b

ICETRAY_CONTAINER="/cvmfs/software.pacific-neutrino.org/containers/itray_v1.17.1"
GRAPHNET_IMAGE="docker://rorsoe/graphnet:graphnet-1.8.0-cu126-torch26-ubuntu-22.04"

BASEDIR="/usr/local/icetray"
GRAPHNET_SRC="/project/def-nahee/kbas/graphnet/src"
EXAMPLE_DIR="/project/def-nahee/kbas/graphnet/examples/08_pone"

# ────────────────────────────────────────────────
echo "========================================"
echo "  PART 1: IceTray + GraphNeT (CPU)"
echo "========================================"

apptainer exec \
  -B /localscratch/ \
  -B /cvmfs/software.pacific-neutrino.org/ \
  -B /project \
  "${ICETRAY_CONTAINER}" \
  bash -lc "
    set -euo pipefail
    export PATH=${BASEDIR}/build/bin:\${PATH}
    export LD_LIBRARY_PATH=${BASEDIR}/build/lib:\${LD_LIBRARY_PATH:-}
    export PYTHONPATH=/usr/local/lib:${BASEDIR}/build/lib:${GRAPHNET_SRC}:\${PYTHONPATH:-}
    export I3_SRC=${BASEDIR}
    export I3_BUILD=${BASEDIR}/build

    python3 -u - <<'PYEOF'
import sys
print(f'Python: {sys.version}')

print('\n--- IceTray ---')
from icecube import icetray, dataio, dataclasses
print('icetray: OK')

print('\n--- PyTorch (CPU) ---')
import torch
print(f'torch: {torch.__version__}')
print(f'CUDA available: {torch.cuda.is_available()}')

print('\n--- GraphNeT (from src) ---')
import graphnet
print(f'graphnet: {graphnet.__version__}')
from graphnet.models.gnn import DynEdge
from graphnet.models.standard_model import StandardModel
from graphnet.training.loss_functions import LogCoshLoss, VonMisesFisher2DLoss
from graphnet.utilities.maths import eps_like
print('graphnet imports: OK')

print('\n=== PART 1 ALL OK ===')
PYEOF
  "

# ────────────────────────────────────────────────
echo ""
echo "========================================"
echo "  PART 2: GraphNeT GPU (training env)"
echo "========================================"

apptainer exec --nv --cleanenv \
  --env PYTHONNOUSERSITE=1 \
  --env PYTHONPATH="${GRAPHNET_SRC}:${EXAMPLE_DIR}" \
  --bind /project \
  "${GRAPHNET_IMAGE}" \
  python3 -u - <<'PYEOF'
import sys
print(f'Python: {sys.version}')

print('\n--- PyTorch + CUDA ---')
import torch
print(f'torch: {torch.__version__}')
print(f'CUDA available: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'CUDA version: {torch.version.cuda}')
    print(f'GPU: {torch.cuda.get_device_name(0)}')
    t = torch.tensor([1.0]).cuda()
    print(f'GPU tensor test: {t}')
else:
    print('WARNING: CUDA not available!')

print('\n--- PyTorch Lightning ---')
import pytorch_lightning as pl
print(f'pytorch_lightning: {pl.__version__}')

print('\n--- GraphNeT ---')
import graphnet
print(f'graphnet: {graphnet.__version__}')
from graphnet.models.gnn import DynEdge
from graphnet.models.standard_model import StandardModel
from graphnet.models.task.reconstruction import (
    AzimuthReconstructionWithKappa,
    ZenithReconstructionWithKappa,
)
from graphnet.training.callbacks import GraphnetEarlyStopping, PiecewiseLinearLR
from graphnet.training.loss_functions import LogCoshLoss, VonMisesFisher2DLoss
from graphnet.utilities.maths import eps_like
print('graphnet imports: OK')

print('\n--- Utils (examples/08_pone) ---')
from utils import (
    DepositedEnergyLog10Task,
    EpochCSVLogger,
    EpochTimeLogger,
    ValidationResidualAndLRMetrics,
    _EpochContextCallback,
    build_data,
    install_logging_filters,
    move_batch_to_device,
    run_test,
)
print('utils imports: OK')

print('\n=== PART 2 ALL OK ===')
PYEOF
