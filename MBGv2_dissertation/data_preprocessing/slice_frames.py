import argparse

from sahi.scripts.slice_coco import slice  # type: ignore


"""
MBGv2 Frame Slicing

This script slices original 4K resolution frames from MBGv2 into 640x640 samples
with overlapping regions using the SAHI library. It also generates COCO annotations for sliced objects.
This step is required to detect small objects (breeding sites such as tires) in high-resolution images.

Usage:
    python slice_frames.py --image_dir path/to/images --dataset_json_path path/to/annotations.json

Example:
    python slice_frames.py --image_dir ./images --dataset_json_path ./annotations.json --slice_size 640 --overlap_ratio 0.2

Features:
    - Configurable slice size and overlap ratio
    - Automatic handling of annotation coordinates
    - Filters out negative samples by default
    - Supports minimum area ratio filtering
"""


def parse_arguments():
    parser = argparse.ArgumentParser(
        description="Slice images from a dataset and its COCO annotations into smaller samples with overlapping regions."
    )

    parser.add_argument(
        "--image_dir",
        type=str,
        required=True,
        help="Path to the directory containing images.",
    )
    parser.add_argument(
        "--dataset_json_path",
        type=str,
        required=True,
        help="Path to the COCO JSON file.",
    )
    parser.add_argument(
        "--slice_size", type=int, default=640, help="Dimensions of each slice (default: 640x640)."
    )
    parser.add_argument(
        "--overlap_ratio",
        type=float,
        default=0.067,
        help="Overlap ratio between slices (default: 0.067).",
    )
    parser.add_argument(
        "--output_dir",
        type=str,
        default="runs/slice_coco",
        help="Directory to save the sliced dataset (default: runs/slice_coco).",
    )
    parser.add_argument(
        "--min_area_ratio",
        type=float,
        default=0.0,
        help="Minimum area ratio for annotations to keep (default: 0.0). Range from 0 to 1.",
    )

    return parser.parse_args()


def main():
    args = parse_arguments()
    print("Arguments received:")
    print(args)
    # Slice frames
    slice(
        image_dir=args.image_dir,
        dataset_json_path=args.dataset_json_path,
        slice_size=args.slice_size,
        overlap_ratio=args.overlap_ratio,
        ignore_negative_samples=True,
        output_dir=args.output_dir,
        min_area_ratio=args.min_area_ratio,
    )


if __name__ == "__main__":
    main()
