import argparse
import json
import os

"""
This script removes all image files that don't contain any object annotations
(negative samples).

This step is necessary to reduce storage usage, 
as sahi will only filter these samples in the annotations,
but all image slices are saved regardless.
"""


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Remove images without objects in COCO annotations."
    )

    parser.add_argument(
        "--images_folder",
        type=str,
        required=True,
        help="Path to the folder containing images.",
    )
    parser.add_argument(
        "--coco_annotation_file",
        type=str,
        required=True,
        help="Path to the COCO annotation JSON file.",
    )

    return parser.parse_args()


def remove_empty_samples(images_folder: str, coco_annotation_file: str) -> None:
    # Assert that both the images folder and annotation file exist
    assert os.path.exists(images_folder), (
        f"Error: Images folder '{images_folder}' does not exist."
    )
    assert os.path.exists(coco_annotation_file), (
        f"Error: COCO annotation file '{coco_annotation_file}' does not exist."
    )

    # Log the paths being used
    print(f"Opening images folder: {images_folder}")

    with open(coco_annotation_file, "r") as f:
        print(f"Reading COCO annotation file: {coco_annotation_file}")
        coco_data = json.load(f)

    # Get the mapping of image file names to IDs
    image_id_to_filename = {img["id"]: img["file_name"] for img in coco_data["images"]}

    # Log the number of images in the annotations
    print(f"Number of images in annotations: {len(image_id_to_filename)}")

    # Iterate through images in the folder and delete those without annotations
    for image in os.listdir(images_folder):
        if image not in image_id_to_filename.values():
            os.remove(os.path.join(images_folder, image))
            continue

    print("Removed all slices without object annotations.")


if __name__ == "__main__":
    args = parse_arguments()
    remove_empty_samples(args.images_folder, args.coco_annotation_file)
