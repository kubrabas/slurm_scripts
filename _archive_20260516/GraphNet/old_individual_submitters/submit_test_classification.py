"""
Submit a classification test job to SLURM.

Usage:
    python3 submit_test_classification.py -c configs/classification/exp001.yml
    python3 submit_test_classification.py -c configs/classification/exp001.yml --dry-run
"""

import argparse
import os
import re
import subprocess
from pathlib import Path

import yaml

WORKER_SH  = Path("/home/kbas/SlurmScripts/GraphNet/test_classification.sh")
LOG_BASE   = "/home/kbas/scratch"


def _mc_log_name(mc: str) -> str:
    if mc == "340StringMC":
        return "String340MC"
    return mc


def _geometry_log_name(geometry: str) -> str:
    return "".join(part.capitalize() for part in geometry.split("_"))


def parse_job_id(sbatch_output: str) -> str:
    m = re.search(r"Submitted batch job (\d+)", sbatch_output)
    return m.group(1) if m else "unknown"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("-c", "--config",  required=True, help="Path to YAML config file")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    config_path = os.path.abspath(args.config)
    with open(config_path) as f:
        cfg = yaml.safe_load(f)

    mc       = cfg["mc"]
    geometry = cfg["geometry"]
    exp_name = cfg["experiment_name"]

    job_name = f"cls_test_{mc}_{geometry}_{exp_name}"
    logfile  = os.path.join(
        LOG_BASE,
        _mc_log_name(mc),
        "GraphnetLogs",
        _geometry_log_name(geometry),
        "Classification",
        f"{exp_name}_{job_name}.out",
    )

    print(f"job_name : {job_name}")
    print(f"config   : {config_path}")
    print(f"logfile  : {logfile}")

    if args.dry_run:
        print("[DRY-RUN] would submit")
        return 0

    cmd = [
        "sbatch",
        f"--job-name={job_name}",
        f"--export=CONFIG={config_path},LOGFILE={logfile}",
        str(WORKER_SH),
    ]

    result   = subprocess.run(cmd, capture_output=True, text=True, check=True)
    job_id   = parse_job_id(result.stdout)
    print(f"submitted: job_id={job_id}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
