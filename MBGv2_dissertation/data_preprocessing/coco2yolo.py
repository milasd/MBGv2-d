import argparse
import json
import numpy as np

from collections import defaultdict
from pathlib import Path
from tqdm import tqdm
from typing import Optional


"""
COCO to YOLO Annotation Conversion

This script converts COCO JSON annotations to YOLO ultralytics format.
It automatically organizes output into train/val folders based on 
the original COCO json filenames.

Script modified from: JSON2YOLO (https://github.com/ultralytics/JSON2YOLO)

Usage:
    python coco2yolo.py --json_dir path/to/json/files [--output_dir path/to/output]

Example:
    python coco2yolo.py --json_dir ./annotations --output_dir ./yolo_labels

Features:
    - Converts COCO bbox format to YOLO normalized format
    - Automatically creates train/val subdirectories, suitable for YOLO ultralytics training
    - Skips crowd annotations and invalid bounding boxes
    - Removes duplicate annotations
"""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Convert COCO JSON annotations to YOLO format."
    )
    parser.add_argument(
        "--json_dir",
        required=True,
        type=Path,
        help="Directory containing COCO JSON files",
    )
    parser.add_argument(
        "--output_dir",
        required=False,
        type=Path,
        help="Directory to save YOLO formatted labels folder (optional). If not provided, annotations will be saved inside [json_dir]/labels",
    )
    args = parser.parse_args()
    return args


def convert_coco_json(json_dir: Path, output_dir: Optional[Path] = None) -> None:
    """Converts COCO JSON format to YOLO label format, with options for segments."""
    if not output_dir:
        output_dir = json_dir

    # Import json
    for json_file in sorted(json_dir.resolve().glob("*.json")):
        # Get the subdirectory based on the annotation file name
        if "train" in json_file.stem:
            subfolder = "train"
        elif "val" in json_file.stem:
            subfolder = "val"
        else:
            subfolder = ""

        # Output folder for YOLO annotations
        fn = Path(output_dir) / "labels" / subfolder
        fn.mkdir(parents=True, exist_ok=True)
        with open(json_file) as f:
            data = json.load(f)

        # Create image dict
        images = {"{:g}".format(x["id"]): x for x in data["images"]}
        # Create image-annotations dict
        imgToAnns = defaultdict(list)
        for ann in data["annotations"]:
            imgToAnns[ann["image_id"]].append(ann)

        # Write labels file
        for img_id, anns in tqdm(
            imgToAnns.items(), desc=f"Annotations {json_file}", position=1
        ):
            img = images[f"{img_id:g}"]
            h, w, f = img["height"], img["width"], img["file_name"]

            bboxes = []
            for ann in anns:
                if ann["iscrowd"]:
                    continue
                # The COCO box format is [top left x, top left y, width, height]
                box = np.array(ann["bbox"], dtype=np.float64)
                box[:2] += box[2:] / 2  # xy top-left corner to center
                box[[0, 2]] /= w  # normalize x
                box[[1, 3]] /= h  # normalize y
                if box[2] <= 0 or box[3] <= 0:  # if w <= 0 and h <= 0
                    continue

                cls = ann["category_id"]  # class
                box = [cls] + box.tolist()
                if box not in bboxes:
                    bboxes.append(box)

            # Write
            with open((fn / f).with_suffix(".txt"), "a") as file:  # type: ignore
                for i in range(len(bboxes)):
                    line = (*(bboxes[i]),)  # cls, box or segments
                    file.write(("%g " * len(line)).rstrip() % line + "\n")


def main():
    args = parse_args()

    convert_coco_json(args.json_dir, args.output_dir)


if __name__ == "__main__":
    main()
