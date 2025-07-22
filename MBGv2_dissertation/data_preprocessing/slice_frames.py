import argparse
from sahi.scripts.slice_coco import slice  # type: ignore


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
        "--slice_size", type=int, default=512, help="Size of each slice (default: 512)."
    )
    parser.add_argument(
        "--overlap_ratio",
        type=float,
        default=0.2,
        help="Overlap ratio between slices (default: 0.2).",
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
        help="Minimum area ratio for annotations to keep (default: 0.0).",
    )

    return parser.parse_args()


if __name__ == "__main__":
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
