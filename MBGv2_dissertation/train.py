"""
YOLO Model Finetuning and Evaluation Script.

This script provides functionality for training YOLO models and evaluating their
performance with F1 score analysis and optimal threshold detection.

Usage:
    python train.py --data_config path/to/data.yaml --hyp_config path/to/hyp.yaml

Example:
    python train.py --data_config data.yaml --hyp_config hyp.yaml --n_runs 3 --device 0
"""

# import pdb
import argparse
import numpy as np
import pandas as pd

from pathlib import Path
from typing import List, Tuple
from ultralytics import YOLO  # type: ignore[import-untyped]
from ultralytics.utils.metrics import DetMetrics  # type: ignore[import-untyped]

from MBGv2_dissertation.utils.logging import get_logger

logger = get_logger(__name__)


def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Train a YOLO model and evaluate average F1 scores."
    )
    parser.add_argument(
        "--data_config",
        type=Path,
        default="",
        help="Path to the data configuration file (YAML) for YOLO",
    )
    parser.add_argument(
        "--hyp_config",
        type=Path,
        default="",
        help="Path to the hyperparameter configuration file (YAML) for YOLO",
    )
    parser.add_argument(
        "--out_dir",
        type=Path,
        default=Path(__file__).resolve().parent / "results",
        help="Output directory for results (default: '[current directory]/results')",
    )
    parser.add_argument(
        "--n_runs",
        type=int,
        default=1,
        help="Number of independent training runs (default: 1)",
    )
    parser.add_argument(
        "--device", type=int, default=0, help="GPU Device ID (default: 0)"
    )

    args = parser.parse_args()

    return args


def calculate_optimal_threshold(
    confidence_scores: np.ndarray, f1_scores: np.ndarray
) -> float:
    """
    Calculate optimal threshold by finding the confidence score that yields
    the highest average F1 score for detections above that threshold.

    Args:
        confidence_scores: Array of confidence scores from validation
        f1_scores: Array of corresponding F1 scores from validation

    Returns:
        float: Optimal confidence threshold
    """
    sorted_indices = np.argsort(confidence_scores)[::-1]
    sorted_confidence = confidence_scores[sorted_indices]
    sorted_f1 = f1_scores[sorted_indices]

    thresholds = np.arange(0, 1.02, 0.02)

    best_threshold = 0.0
    best_avg_f1 = 0.0
    threshold_results = []

    for threshold in thresholds:
        cutoff_idx = np.searchsorted(-sorted_confidence, -threshold, side="right")

        if cutoff_idx == 0:
            # No detections above this threshold
            avg_f1 = 0.0
            num_detections = 0
        else:
            # Calculate average F1 for detections above threshold
            relevant_f1 = sorted_f1[:cutoff_idx]
            avg_f1 = np.mean(relevant_f1)
            num_detections = cutoff_idx

        threshold_results.append(
            {"threshold": threshold, "avg_f1": avg_f1, "num_detections": num_detections}
        )

        if avg_f1 > best_avg_f1:
            best_avg_f1 = avg_f1
            best_threshold = threshold

    logger.info("\nThreshold Analysis:")
    logger.info("-" * 45)
    logger.info(f"Best Average F1: {best_avg_f1:.4f}")
    return best_threshold


def process_evaluation_metrics(
    metrics: DetMetrics,
) -> Tuple[float, pd.DataFrame, float]:
    """
    Processes evaluation metrics to calculate the average of all F1 scores,
    as well as the average F1 score separated by detection confidence score intervals of 0.05 for display,
    and calculates optimal detection confidence threshold.

    Args:
        metrics: The metrics object returned by model.val().

    Returns:
        Tuple containing:
        - float: Overall average F1 score
        - pandas.DataFrame: DataFrame with confidence bins and average F1 per bin
        - float: Optimal confidence threshold
    """
    confidence_scores = metrics.curves_results[1][0].flatten()
    f1_scores = metrics.curves_results[1][1].flatten()

    optimal_threshold = calculate_optimal_threshold(confidence_scores, f1_scores)

    bins = np.arange(0, 1.05, 0.05).tolist()
    df = pd.DataFrame({"confidence": confidence_scores, "f1": f1_scores})
    df["confidence_bin"] = pd.cut(df["confidence"], bins, include_lowest=True)
    average_f1_per_bin = df.groupby("confidence_bin")["f1"].mean().reset_index()
    overall_avg_f1 = np.mean(f1_scores)

    return overall_avg_f1, average_f1_per_bin, optimal_threshold


def train_and_evaluate(
    data_config: Path,
    hyp_config: Path,
    out_dir: Path,
    n_runs: int,
    device: int,
    yolo_model: str = "yolov8s.pt",
) -> None:
    """
    Train a YOLO model (default YOLOv8s) and analyze F1 score consistency.

    This function can perform multiple training runs and evaluates the
    average F1 scores across different detection confidence scores,
    providing optimal confidence thresholds.

    Args:
        data_config (Path): Path to the YAML data configuration file containing dataset
            information (train/val paths, class names, number of classes).
        hyp_config (Path): Path to the YAML hyperparameter configuration file containing
            training parameters (learning rate, batch size, epochs, etc.).
        out_dir (Path): Output directory where training results, models, and logs will
            be saved. Each run creates a subdirectory within this path.
        n_runs (int): Number of independent training runs to perform.
            Each training run is independent and starts from the same YOLO pretrained weights.
        device (int): GPU device ID to use for training and evaluation. Use 0 for the
            first GPU, 1 for the second, etc. CPU training is not recommended.
    """
    all_runs_f1_bins: List[np.ndarray[tuple[int], np.dtype[np.float64]]] = []
    all_runs_overall_f1_avg: List[float] = []

    for i in range(n_runs):
        logger.info(f"Starting training run {i + 1}/{n_runs}...")
        model = YOLO(yolo_model)
        model.train(
            data=data_config,
            cfg=hyp_config,
            device=device,
            optimizer="Adam",
            project=out_dir,
        )

        metrics = model.val(data=data_config, save_json=True)
        overall_avg_f1, average_f1_per_bin, optimal_threshold = (
            process_evaluation_metrics(metrics)
        )

        all_runs_overall_f1_avg.append(overall_avg_f1)
        f1_values = average_f1_per_bin["f1"].to_numpy(dtype=np.float64)
        all_runs_f1_bins.append(f1_values)
        # all_runs_f1_bins.append(average_f1_per_bin['f1'].values)

    average_f1_across_runs = np.mean(all_runs_f1_bins, axis=0)
    average_f1_per_bin["average_f1_across_runs"] = average_f1_across_runs

    logger.info("\nAverage F1 per Confidence Interval (All Runs):")
    logger.info(average_f1_per_bin[["confidence_bin", "average_f1_across_runs"]])
    logger.info(
        f"\nOverall Average F1 (All Runs): {np.mean(all_runs_overall_f1_avg):.3f}"
    )
    logger.info(f"\nOptimal τ: {optimal_threshold:.2f}\n")


def main() -> None:
    args = parse_args()

    train_and_evaluate(
        data_config=args.data_config,
        hyp_config=args.hyp_config,
        out_dir=args.out_dir,
        n_runs=args.n_runs,
        device=args.device,
    )


if __name__ == "__main__":
    main()
