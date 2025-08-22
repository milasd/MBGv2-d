# MBGv2 - Pipeline scripts

This directory contains shell scripts for automating the MBGv2 dataset processing and YOLO model training pipelines.

## Scripts Overview

### Frame Slicing Pipeline
- **`frame_slicing/process_all_folds.sh`**: Processes all 5 folds of the MBGv2 dataset, slicing 4K frames into 640x640 excerpts with overlapping regions and generating COCO and YOLO format annotations.

The default parameters follow the slicing process for tires.

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

### Model Training

The `train_all_folds.sh` script trains YOLOv8s models across all 5 folds with the sliced dataset.

**Basic usage:**
```bash
chmod +x sh/yolo/train_all_folds.sh
.sh/yolo/train_all_folds.sh --data-dir [path to sliced dataset dir]
```

You can run the help command for the full documentation:

```
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
    ./sh/yolo/train_all_folds.sh --data-dir [path to base data dir] --num-runs 3

    # or

    ./sh/yolo/train_all_folds.sh --data_dir /home/[path to base data dir] --results-dir /home/[path to custom results dir] --num-runs 5 --device 1
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