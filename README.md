# MBGv2: Frame slicing and small object detection

This repository contains the complete codebase for experiments with the MBGv2 dataset reported in my dissertation. The project focuses on object detection in high-resolution (4K) images using frame slicing techniques, then further fine-tuning YOLO models.


The codebase enables execution of two main experiments:

### 1. Frame Slicing with Annotation Generation
Slices 4K resolution frames from the MBGv2 dataset into 640x640 excerpts with overlapping regions, automatically generating annotations in both COCO and YOLO formats for sliced objects. This preprocessing step is essential for detecting small objects (such as mosquito breeding sites like tires) in high-resolution images.

### 2. YOLO Model Fine-tuning
Further trains a YOLO model (default: YOLOv8s) on the sliced dataset. The default settings follow the experimental configuration used in the dissertation but can be customized for additional experimentation.


## Installation

### Prerequisites

First, install [uv](https://docs.astral.sh/uv/), a fast Python package manager:

```bash
# On macOS and Linux
curl -LsSf https://astral.sh/uv/install.sh | sh
```


Then clone the repository and install the project dependencies:

```bash
cd MBGv2-dissertation

# Install all dependencies
uv venv && uv sync
```

## How to Run

The `sh` folder contains shell scripts for the frame slicing and training pipelines. 


The commands below show the basic command lines to reproduce the experiments from the dissertation. For detailed information on customizable parameters, [read the 'sh' folder README.md](sh/README.md).

### Frame Slicing

To reproduce the frame slicing experiments — which slice annotated 4K frames from the MBGv2 dataset into 640x640 excerpts with overlapping regions:

```bash
chmod +x sh/frame_slicing/process_all_folds.sh

# Run the script
./sh/frame_slicing/process_all_folds.sh \
  --image-dir /path/to/mbgv2/frames \
  --annotations-dir /path/to/annotations \
  --overlap-ratio 0.067 \
  --object-name tire
```
The output will contain train/val folders containing the sliced images, COCO and YOLO annotations.

**Parameters:**
- **Overlap ratio**: 0.067 (equivalent to 42px for tires, based on the maximum dimension of average object resolution)
- **Slice size**: 640x640 pixels


**Custom parameters example:**
```bash
chmod +x sh/frame_slicing/process_all_folds.sh
bash sh/frame_slicing/process_all_folds.sh \
  --image-dir [path to folder containing frames (images)] \
  --annotations-dir [path to dir w/ COCO annotations] \
  --overlap-ratio 0.067 \
  --object-name tire
```

### Model Training (Fine-tuning)

Subsequently train and validate a YOLOv8s model with the sliced dataset:

```bash
chmod +x sh/yolo/train_all_folds.sh
bash sh/yolo/train_all_folds.sh
```

This script will reproduce the training and evaluation across the 5 folds for the MBGv2.
It will also display the average F1 score for each fold, as well as the optimal threshold for detection.


## Expected Data Structure

To run the experiments, you must have the MBGv2 dataset. 
This codebase is structured to process the dataset published in Isabelle Vaz de Mello (2024)'s experiments with Faster-RCNN, which includes frames and COCO annotations:

### Input (MBGv2 Dataset)
```
MBGv2_dataset/
├── frames/                      # Original 4K resolution images
│   ├── image1.jpg
│   ├── image2.jpg
│   └── ...
└── coco_json_folds/            # COCO annotations organized by folds
    └── 5folds/
        └── tire/               # Object class (tire|watertank)
            └── 40m/            # Drone height parameter
                ├── coco_format_.json
                ├── fold1_val.json
                └── ...
```

### Output (After Processing)
```
MBGv2_sliced/                   # Sliced dataset
├── fold1/
│   └── 00/                     # Min area ratio folder
│       ├── data.yaml           # YOLO dataset configuration
│       ├── images/             # Sliced 640x640 images
│       ├── labels/             # YOLO format annotations
│       └── coco_annotations/   # COCO format annotations
└── ...

results/                        # Training results
├── fold1/
│   ├── run1/                   # Individual training runs
│   └── ...
├── fold1.log                   # Training logs
└── ...
```

## Development

```bash
# Run all tests
uv run make test

# Format code
uv run make format

# Lint code
uv run make check
```

## Configuration

### Hyperparameter Files
- `config/hyp.mosquito.tire.yaml`: Settings for tire detection
- `config/hyp.mosquito.watertank.yaml`: Settings for watertank detection
