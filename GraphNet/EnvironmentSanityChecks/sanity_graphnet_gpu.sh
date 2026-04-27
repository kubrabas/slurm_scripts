#!/bin/bash
#SBATCH --job-name=sanity_graphnet_gpu
#SBATCH --account=def-nahee
#SBATCH --time=00:30:00
#SBATCH --mem=16G
#SBATCH --gpus-per-node=nvidia_h100_80gb_hbm3_1g.10gb:1
#SBATCH --cpus-per-task=2
#SBATCH --output=/home/kbas/SlurmScripts/GraphNet/EnvironmentSanityChecks/Logs/%x_%j.out
#SBATCH --error=/home/kbas/SlurmScripts/GraphNet/EnvironmentSanityChecks/Logs/%x_%j.out

module --force purge
module load StdEnv/2020 gcc/11.3.0 apptainer scipy-stack/2023b

GRAPHNET_SRC="/project/def-nahee/kbas/graphnet/src"
EXAMPLE_DIR="/project/def-nahee/kbas/graphnet/examples/08_pone"
IMAGE="docker://rorsoe/graphnet:graphnet-1.8.0-cu126-torch26-ubuntu-22.04"

apptainer exec --nv --cleanenv \
  --env PYTHONNOUSERSITE=1 \
  --env PYTHONPATH="${GRAPHNET_SRC}:${EXAMPLE_DIR}" \
  --bind /project \
  "${IMAGE}" \
  python3 -u - <<'PYEOF'
import sys
print("=== Python ===")
print(f"Python: {sys.version}")

print("\n=== PyTorch ===")
import torch
print(f"torch: {torch.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")
if torch.cuda.is_available():
    print(f"CUDA version: {torch.version.cuda}")
    print(f"GPU: {torch.cuda.get_device_name(0)}")
    t = torch.tensor([1.0]).cuda()
    print(f"GPU tensor test: {t}")
else:
    print("WARNING: CUDA not available!")

print("\n=== PyTorch Lightning ===")
import pytorch_lightning as pl
print(f"pytorch_lightning: {pl.__version__}")

print("\n=== GraphNeT ===")
import graphnet
print(f"graphnet: {graphnet.__version__}")
from graphnet.models.gnn import DynEdge
from graphnet.models.standard_model import StandardModel
from graphnet.models.task.reconstruction import (
    AzimuthReconstructionWithKappa,
    ZenithReconstructionWithKappa,
)
from graphnet.training.callbacks import GraphnetEarlyStopping, PiecewiseLinearLR
from graphnet.training.loss_functions import LogCoshLoss, VonMisesFisher2DLoss
from graphnet.utilities.maths import eps_like
print("graphnet imports: OK")

print("\n=== Utils (examples/08_pone) ===")
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
print("utils imports: OK")

print("\n=== Other ===")
import yaml
print(f"yaml: OK")

print("\n=== ALL CHECKS PASSED ===")
PYEOF
