# MBGv2 - Pipeline scripts

This directory contains shell scripts for automating the MBGv2 dataset processing and YOLO model training pipelines.

## Scripts Overview

### Frame Slicing Pipeline
- **`frame_slicing/process_all_folds.sh`**: Processes all 5 folds of the MBGv2 dataset, slicing 4K frames into 640x640 excerpts with overlapping regions and generating COCO and YOLO format annotations. The default parameters follow the slicing process for tires.

- **`frame_slicing/custom_fold_processing.sh`**: Flexible frame slicing script with customizable fold selection, dataset splits, and min_area_ratio values. Supports incremental processing and partial dataset generation.

### Model Training Pipeline  
- **`yolo/train_all_folds.sh`**: Trains YOLOv8s models across all 5 folds using the sliced dataset with customizable parameters.


## Detailed Usage

### Frame Slicing

The `process_all_folds.sh` script slices annotated 4K frames from the MBGv2 dataset into 640x640 excerpts with overlapping regions. The default parameters follow the settings on 

**Basic usage:**
```bash
chmod +x sh/frame_slicing/process_all_folds.sh
bash sh/frame_slicing/process_all_folds.sh
```

You can run the help command for the full documentation:

```bash
# Script documentation
./sh/frame_slicing/process_all_folds.sh --help

Usage: ./sh/frame_slicing/process_all_folds.sh [OPTIONS]

Slices MBGv2 dataset frames containing tires across multiple folds,
considering all min_area_ratio values (0.0, 0.1, ..., 0.9, 1.0).

After the script is finished, the output folder './MBGv2_sliced' should contain
one directory for each fold from 1 to 5. Each fold directory contains 
1 folder for each min_area_ratio value ranging from 0.0, 0.1, ..., 1.0.

Each output min_area_ratio folder (00, 01, ..., 10) contains:

  - images/ and labels/: Directories containing sliced frames for fold train/val and the YOLO annotations
                          for this min_area_ratio.
  - mosquito_{object}_fold{1-5}_{OVERLAP_RATIO}.yaml: YAML config file for YOLO training with ultralytics.
  - coco_format_{train|val}{0-4}_640_{OVERLAP_RATIO}.json: Pair of train/val COCO annotations of sliced frames
                                                          for this min_area_ratio.



OPTIONS:
    --image-dir DIR         Path to directory containing frames from MBGv2 dataset
                                (4K resolution images)
    --annotations-dir DIR   Path to directory containing COCO annotations in .json format
                               (should contain fold structure with train/val JSON files as: 
                                coco_format_train{0-4}_{object_name}.json and 
                                coco_format_val{0-4}_{object_name}.json.
                                Example: coco_format_train0_tire.json, coco_format_val1_watertank.json)
    --slice-size SIZE       Size of image slices (default: 640)
    --overlap-ratio NUM     Overlap ratio between slices (default: 0.067, for MBGv2 tires)
    --object_name TEXT      Class of MBGv2 object in annotations (default: tire)
    --output_dir DIR        Path to output directory (default: ./MBGv2_sliced)
    --help                  Show this help message and exit



EXAMPLES:
    ./sh/frame_slicing/process_all_folds.sh --image-dir data_mosquitoes_v2/frames --annotations-dir data_mosquitoes_v2/coco_json_folds/5folds/tire/40m
    ./sh/frame_slicing/process_all_folds.sh --image-dir ./frames --annotations-dir ./annotations --slice-size 512 --overlap-ratio 0.1



INPUT MBGv2 COCO ANNOTATIONS:
    The input MBGv2 COCO annotations are separated in train and val json files and follow the pattern
    coco_format_{train|val}{0-4}_{object}.json. Examples:

      ── coco_format_train0_tire.json, coco_format_val0_tire.json 
      ── coco_format_train0_watertank.json, coco_format_val0_watertank.json



OUTPUT DIRECTORY STRUCTURE:

{output_dir_name}/
└── {object_name}/
    ├── fold1/
    │   ├── 00/
    │   │   ├── images/
    │   │   │   ├── train/
    │   │   │   └── val/
    │   │   ├── labels/
    │   │   │   ├── train/
    │   │   │   └── val/
    │   │   ├── coco_format_train0_tire_640_0067.json
    │   │   ├── coco_format_val0_tire_640_0067.json
    │   │   └── mosquito_tire_fold1_0067.yaml
    │   ├── 01/
    │   │   └── ...
    │   ├── 02/
    │   │   └── ...
    │   ├── ...
    │   └── 10/
    │       └── ...
    ├── fold2/
    │   └── ...
    ├── fold3/
    │   └── ...
    ├── fold4/
    │   └── ...
    └── fold5/
        └── ...
```



**Example with custom parameters**

Slicing for watertanks:

```bash
chmod +x sh/frame_slicing/process_all_folds.sh
bash sh/frame_slicing/process_all_folds.sh \
  --image-dir /path/to/mbgv2/frames \
  --annotations-dir /path/to/dir/annotations \
  --output-dir ./custom_output_dir \
  --overlap-ratio 0.1 \
  --object-name watertank
```

### Custom Frame Slicing

The `custom_fold_processing.sh` script provides flexible frame slicing with granular control over folds, dataset splits, and min_area_ratio values. This script is ideal for custom experiments or incremental processing.

**Slicing options:**
- **Custom fold selection**: Process specific folds or ranges (e.g., `"0,2-4"`, `"1,3"`, `"0-20"`, `"2"`)
- **Flexible dataset splits**: Choose which splits to process (`"train"`, `"val"`, `"test"`, `"train val test"`, etc.)
- **Custom min_area_ratio ranges**: Define specific values (`"0.0,0.5,1.0"` or `"0.0"`) or ranges (`"0.5-0.8"`)
- **Incremental processing**: Updates existing YAML files instead of overwriting them

**Basic usage**

Run the script passing the required parameters.
```bash
chmod +x sh/frame_slicing/custom_fold_processing.sh

# Basic usage with mandatory parameters
./sh/frame_slicing/custom_fold_processing.sh \
  --image-dir "/path/to/frames" \
  --annotations-dir "/path/to/annotations" \
  --object-name "tire" \
  --overlap-ratio 0.067 \
  --folds "0-4" \
  --splits "train val" \
  --min-area-ratios "0.0-1.0"
```

**Full documentation:**
```bash
./sh/frame_slicing/custom_fold_processing.sh --help

Usage: ./sh/frame_slicing/custom_fold_processing.sh [OPTIONS]

Customizable script for slicing MBGv2 dataset frames containing objects across 
specified folds, dataset splits, and min_area_ratio values.

OPTIONS:
    --image-dir DIR         Path to directory containing frames from MBGv2 dataset
                                (4K resolution images)
    --annotations-dir DIR   Path to directory containing COCO annotations in .json format
                               (should contain fold structure with train/val/test JSON files as: 
                                coco_format_{split}{0-4}_{object_name}.json)
    --slice-size SIZE       Size of image slices (default: 640)
    --overlap-ratio NUM     Overlap ratio between slices (default: 0.067, for MBGv2 tires)
    --object-name TEXT      Class of MBGv2 object in annotations (default: tire)
    --output-dir DIR        Path to output directory (default: ./MBGv2_sliced)
    --folds LIST            Comma-separated list of fold numbers (e.g., "0,1,2" or "0-4" or "1,3")
                               (default: "0-4")
    --splits LIST           Space-separated list of dataset splits to process
                               (e.g., "train", "train val", "train val test")
                               (default: "train val")
    --min-area-ratios LIST  Comma-separated list of min_area_ratio values
                               (e.g., "0.0,0.5,1.0" or "0.0-1.0" or "0.5")
                               (default: "0.0-1.0" in steps of 0.1)
    --help                  Show this help message and exit

FOLD SPECIFICATION:
    Folds can be specified as:
    - Single values: "0" or "1,3,5"
    - Ranges: "0-4" (inclusive)
    - Mixed: "0,2-4,7"

MIN_AREA_RATIO SPECIFICATION:
    Min area ratios can be specified as:
    - Single values: "0.5" or "0.0,0.5,1.0"
    - Ranges: "0.0-1.0" (in steps of 0.1) or "0.5-0.8"
    - Mixed: "0.0,0.5-0.8,1.0"

EXAMPLES:
    # Process folds 0-2 with train and val splits
    ./sh/frame_slicing/custom_fold_processing.sh --folds "0-2" --splits "train val"
    
    # Process only fold 0 with all splits and specific min_area_ratios
    ./sh/frame_slicing/custom_fold_processing.sh --folds "0" --splits "train val test" --min-area-ratios "0.0,0.5,1.0"
    
    # Process folds 1 and 3 with only train split
    ./sh/frame_slicing/custom_fold_processing.sh --folds "1,3" --splits "train" --min-area-ratios "0.5-0.8"
```

**Usage Examples**

Process only validation split for specific folds:
```bash
./sh/frame_slicing/custom_fold_processing.sh \
  --image-dir "/path/to/frames" \
  --annotations-dir "/path/to/coco_annotations_dir" \
  --object-name "tire" \
  --overlap-ratio 0.067 \
  --folds "0-3" \
  --splits "val" \
  --min-area-ratios "0.0"
```

Incremental processing (add train split to existing val data):
```bash
# First run: process validation data
./sh/frame_slicing/custom_fold_processing.sh \
  --image-dir "/path/to/frames" \
  --annotations-dir "/path/to/coco_annotations_dir" \
  --object-name "watertank" \
  --overlap-ratio 0.1 \
  --folds "0" \
  --splits "val" \
  --min-area-ratios "0.5"

# Second run: add training data (YAML file will be updated, not overwritten)
./sh/frame_slicing/custom_fold_processing.sh \
  --image-dir "/path/to/frames" \
  --annotations-dir "/path/to/coco_annotations_dir" \
  --object-name "watertank" \
  --overlap-ratio 0.1 \
  --folds "0" \
  --splits "train" \
  --min-area-ratios "0.5"
```

Process large fold ranges with custom min_area_ratios:
```bash
./sh/frame_slicing/custom_fold_processing.sh \
  --image-dir "/path/to/frames" \
  --annotations-dir "/path/to/coco_annotations_dir" \
  --object-name "tire" \
  --overlap-ratio 0.067 \
  --folds "0-20" \
  --splits "train val test" \
  --min-area-ratios "0.0,0.3,0.7,1.0"
```

### Model Training

The `train_all_folds.sh` script trains YOLOv8s models across all 5 folds with the sliced dataset.

**Basic usage:**
```bash
chmod +x sh/yolo/train_all_folds.sh
.sh/yolo/train_all_folds.sh --data-dir [path to sliced dataset dir] --hyp-config [path to yaml hyperparameters config]
```

You can run the help command for the full documentation:

```shell
✗ ./sh/yolo/train_all_folds.sh --help
Usage: ./sh/yolo/train_all_folds.sh [OPTIONS]

For all datasets' .yaml files inside the base data directory (sliced MBGv2), 
train a YOLOv8s model across all 5 folds with customizable parameters.

OPTIONS:
    --data-dir DIR          Path to Base data (sliced MBGv2) directory, which contains fold subdirectories.
    --results-dir DIR       Path to Base results directory (default: results).
    --num-runs INT          Number of independent training runs per fold (default: 1). 
                              Each training run is independent and starts from the same YOLO pretrained weights.
    --device INT            GPU device ID (0, 1, 2, ...) for training (default: 0).
    --hyp-config FILE       Path to YAML file containing hyperparameters for YOLO training (default: config/hyp_mosquito_tire_dissertation.yaml).
    --help                  Show this help message.

EXAMPLE OF EXPECTED BASE DATA DIRECTORY STRUCTURE:
    BASE_DATA_DIR/
    ├── fold1/
    │   └── 00/
    │       ├── *.yaml
    │       └── ...
    │       
    └── ...

EXAMPLES:
    # Use default values (process folds 1-5)
    ./sh/yolo/train_all_folds.sh
    
    # Custom data directory and number of runs
    ./sh/yolo/train_all_folds.sh --data-dir [path to base data dir] --num-runs 3 --hyp-config config/my_custom_hyperparams.yaml


    # Full customization
    ./sh/yolo/train_all_folds.sh --data-dir /home/[path to base data dir] --results-dir /home/[path to custom results dir] --num-runs 5 --device 1 --hyp-config config/my_hyp.yaml
```


## MBGv2 Dataset Structure

The input dataset for the frame slicing process should contain frames (images) and COCO json annotation files separated in train/val.

Make sure that you have a pair of COCO annotations (JSON) files for train and val data for each fold. The file names are expected to follow the pattern `coco_format_{train|val}{0-4}_{object name}.json`.

An example is the MBGv2 dataset structure from Isabelle Vaz de Mello (2024)'s dissertation experiments:

```
MBGv2_dataset/
├── frames/
│   ├── frame0000.jpg
│   ├── frame1333.jpg
│   └── ...
└── coco_json_folds/
    └── 5folds/
        └── tire/
            └── 40m/
                ├── coco_format_train0_tire.json
                ├── coco_format_val0_tire.json
                ├── ...
                ├── coco_format_train4_tire.json
                └── coco_format_val4_tire.json
        └── watertank/
            └── 40m/
                ├── coco_format_train0_watertank.json
                ├── coco_format_val0_watertank.json
                ├── ...
                ├── coco_format_train4_watertank.json
                └── coco_format_val4_watertank.json


```
 

### Output directory structure

Frame slicing:

```
MBGv2_sliced/
├── fold1/
│   └── 00/
│       ├── data.yaml
│       ├── images/
│       ├── labels/
│       └── coco_annotations/
├── fold2/
│   └── 00/
│       └── ...
└── ...
```

Training results:

```
results/
├── fold1/
│   ├── run1/
│   ├── run2/
│   └── ...
├── fold2/
│   └── ...
└── fold1.log, fold2.log, ...
```