"""
Submit the classification train -> test -> plot pipeline to SLURM.

Usage:
    python3 submit_classification_pipeline.py -c /path/to/config.yml
    python3 submit_classification_pipeline.py -c /path/to/config.yml --dry-run
"""

import argparse
import os
import re
import subprocess
from pathlib import Path

import yaml

BASE_DIR = Path("/home/kbas/SlurmScripts/GraphNet")
TRAIN_SH = BASE_DIR / "train_classification.sh"
TEST_SH = BASE_DIR / "test_classification.sh"
PLOT_SH = BASE_DIR / "plot_classification.sh"
def _log_dir(save_dir: str) -> str:
    return os.path.join(save_dir, "logs")


def _prediction_csv(cfg: dict) -> str:
    return os.path.join(
        cfg["output"]["save_dir"],
        cfg["output"].get("test_csv_name", "test_predictions.csv"),
    )


def parse_job_id(sbatch_output: str) -> str:
    m = re.search(r"Submitted batch job (\d+)", sbatch_output)
    if not m:
        raise RuntimeError(f"Could not parse job id from sbatch output: {sbatch_output!r}")
    return m.group(1)


def _sbatch(cmd: list[str], dry_run: bool) -> str:
    print(" ".join(cmd))
    if dry_run:
        return "DRYRUN"
    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    print(result.stdout.strip())
    return parse_job_id(result.stdout)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("-c", "--config", required=True, help="Path to YAML config file")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    config_path = os.path.abspath(args.config)
    with open(config_path) as f:
        cfg = yaml.safe_load(f)

    mc = cfg["mc"]
    geometry = cfg["geometry"]
    exp_name = cfg["experiment_name"]

    log_dir = _log_dir(cfg["output"]["save_dir"])
    train_job_name = f"cls_train_{mc}_{geometry}_{exp_name}"
    test_job_name = f"cls_test_{mc}_{geometry}_{exp_name}"
    plot_job_name = f"cls_plot_{mc}_{geometry}_{exp_name}"

    train_log = os.path.join(log_dir, f"{exp_name}_{train_job_name}.out")
    test_log = os.path.join(log_dir, f"{exp_name}_{test_job_name}.out")
    plot_log = os.path.join(log_dir, f"{exp_name}_{plot_job_name}.out")
    predictions_csv = _prediction_csv(cfg)

    print(f"config          : {config_path}")
    print(f"train logfile   : {train_log}")
    print(f"test logfile    : {test_log}")
    print(f"plot logfile    : {plot_log}")
    print(f"predictions csv : {predictions_csv}")

    train_id = _sbatch(
        [
            "sbatch",
            f"--job-name={train_job_name}",
            f"--export=CONFIG={config_path},LOGFILE={train_log}",
            str(TRAIN_SH),
        ],
        args.dry_run,
    )

    test_dependency = f"afterok:{train_id}" if train_id != "DRYRUN" else "afterok:<train_job_id>"
    test_id = _sbatch(
        [
            "sbatch",
            f"--dependency={test_dependency}",
            f"--job-name={test_job_name}",
            f"--export=CONFIG={config_path},LOGFILE={test_log}",
            str(TEST_SH),
        ],
        args.dry_run,
    )

    plot_dependency = f"afterok:{test_id}" if test_id != "DRYRUN" else "afterok:<test_job_id>"
    plot_id = _sbatch(
        [
            "sbatch",
            f"--dependency={plot_dependency}",
            f"--job-name={plot_job_name}",
            f"--export=CONFIG={config_path},LOGFILE={plot_log},PREDICTIONS_CSV={predictions_csv}",
            str(PLOT_SH),
        ],
        args.dry_run,
    )

    print("submitted pipeline:")
    print(f"  train: {train_id}")
    print(f"  test : {test_id}")
    print(f"  plot : {plot_id}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
