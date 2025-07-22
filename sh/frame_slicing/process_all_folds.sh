#!/bin/bash
#####################################
#  DATA PREPROCESSING:
#
#  Slice frames & 
#  generate COCO & YOLO annotations
#  of a MBGv2 object class
#  (watertanks, tire...)
#
#  For all 5 folds, process data for 
#  all min_area_ratios in range
#  [0.0, 0.1, ..., 1.0]
#
#  TODO: OPTIMIZE the slicing process
#  settings
#####################################

OBJECT_NAME="tire"
SLICE_SIZE=640
OVERLAP_RATIO=0.067

# Default settings, can be overwritten.
MBGv2_DIR="/home/mila.oliveira/repos/data_mosquitoes_v2"
IMAGE_DIR="${MBGv2_DIR}/frames"
ANNOTATIONS_DIR="${MBGv2_DIR}/coco_json_folds/5folds/tire/40m"
BASE_OUT_DIR="MBGv2_sliced"

COCO_YOLO_SCRIPT_PATH="MBGv2_dissertation/data_preprocessing/coco2yolo.py"
REMOVE_EMPTY_SLICES_SCRIPT_PATH="MBGv2_dissertation/data_preprocessing/remove_empty_samples.py"


show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

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
    $0 --image-dir data_mosquitoes_v2/frames --annotations-dir data_mosquitoes_v2/coco_json_folds/5folds/tire/40m
    $0 --image-dir ./frames --annotations-dir ./annotations --slice-size 512 --overlap-ratio 0.1



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


EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        ---image-dir)
            IMAGE_DIR="$2"
            shift 2
            ;;
        --annotations-dir)
            ANNOTATIONS_DIR="$2"
            shift 2
            ;;
        --overlap-ratio)
            OVERLAP_RATIO="$2"
            shift 2
            ;;
        --object-name)
            OBJECT_NAME="$2"
            shift 2
            ;;
        --output-dir)
            BASE_OUT_DIR="$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Error: Unknown option $1"
            echo "Use -h or --help for usage information."
            exit 1
            ;;
    esac
done


# Check if output directory exists and creates it if not
[[ ! -d "$BASE_OUT_DIR" ]] && mkdir -p "$BASE_OUT_DIR"


# Loop over each fold annotations
for FOLD in {0..4}; do
  # Increment fold number by 1 for output directory naming
  OUTPUT_FOLD=$((FOLD + 1))
  
  echo "Processing fold $FOLD (output folder fold${OUTPUT_FOLD}) with train JSON: $COCO_TRAIN_JSON and val JSON: $COCO_VAL_JSON..."
  
  # Loop over min_area_ratio values from 0.0 to 1.0 in steps of 0.1
  # Input COCO annotations pairs follow the naming coco_format_{train|val}{0-4}_{object_name}.json
  # Eg.: coco_format_train0_tire.json, coco_format_val4_watertank.json
  # Construct the train and validation JSON paths for the current fold
  COCO_TRAIN_JSON="${ANNOTATIONS_DIR}/coco_format_train${FOLD}_${OBJECT_NAME}.json"
  COCO_VAL_JSON="${ANNOTATIONS_DIR}/coco_format_val${FOLD}_${OBJECT_NAME}.json"

  # Increment fold number by 1 for output directory naming
  OUTPUT_FOLD=$((FOLD + 1))

  OVERLAP_RATIO_TXT="$OVERLAP_RATIO"
  echo "Processing fold $FOLD (output folder fold${OUTPUT_FOLD}) with train JSON: $COCO_TRAIN_JSON and val JSON: $COCO_VAL_JSON..."
  for MIN_AREA_RATIO in $(seq 0.0 0.1 1.0)
  do
    echo "  Starting process for min_area_ratio=$MIN_AREA_RATIO."
    # Dynamically set output directory based on fold number and min_area_ratio
    MIN_AREA_RATIO_TXT="$MIN_AREA_RATIO"
    OUTPUT_DIR="${BASE_OUT_DIR}/${OBJECT_NAME}/fold${OUTPUT_FOLD}/${MIN_AREA_RATIO_TXT//.}"
    echo "  Output directory: $OUTPUT_DIR"

    mkdir -p $OUTPUT_DIR

    echo "  Processing with min_area_ratio=$MIN_AREA_RATIO, output_dir=$OUTPUT_DIR..."

    # Run SAHI coco slice commands for train and val datasets
    uv run sahi coco slice \
      --ignore_negative_samples \
      --slice_size $SLICE_SIZE \
      --overlap_ratio $OVERLAP_RATIO \
      --min_area_ratio $MIN_AREA_RATIO \
      --output_dir $OUTPUT_DIR \
      --image_dir $IMAGE_DIR \
      --dataset_json_path $COCO_VAL_JSON 
      
    VAL_FOLDER_NAME=$(basename $COCO_VAL_JSON .json)_images_${SLICE_SIZE}_${OVERLAP_RATIO_TXT//.}
    VAL_PATH="$OUTPUT_DIR/$VAL_FOLDER_NAME"

    VAL_JSON_NAME=${VAL_FOLDER_NAME//'_images'}.json
    VAL_JSON_PATH="$OUTPUT_DIR/$VAL_JSON_NAME"

    # Filter slices without any object annotations
    uv run python $REMOVE_EMPTY_SLICES_SCRIPT_PATH --images_folder $VAL_PATH --coco_annotation_file $VAL_JSON_PATH

    uv run sahi coco slice \
      --ignore_negative_samples \
      --slice_size $SLICE_SIZE \
      --overlap_ratio $OVERLAP_RATIO \
      --min_area_ratio $MIN_AREA_RATIO \
      --output_dir $OUTPUT_DIR \
      --image_dir $IMAGE_DIR \
      --dataset_json_path $COCO_TRAIN_JSON 

    # Extract folder and file names from the JSON paths
    TRAIN_FOLDER_NAME=$(basename $COCO_TRAIN_JSON .json)_images_${SLICE_SIZE}_${OVERLAP_RATIO_TXT//.}
    TRAIN_PATH="$OUTPUT_DIR/$TRAIN_FOLDER_NAME"
    
    TRAIN_JSON_NAME=${TRAIN_FOLDER_NAME//'_images'}.json
    TRAIN_JSON_PATH="$OUTPUT_DIR/$TRAIN_JSON_NAME"

    # Filter slices without any object annotations
    uv run python $REMOVE_EMPTY_SLICES_SCRIPT_PATH --images_folder $TRAIN_PATH --coco_annotation_file $TRAIN_JSON_PATH

    mkdir -p "$OUTPUT_DIR/images/train"
    mkdir -p "$OUTPUT_DIR/images/val"

    # Rename the training & validation data folder to "images/train" and "images/val"
    [ -d "$TRAIN_PATH" ] && mv $TRAIN_PATH/* $OUTPUT_DIR/images/train
    [ -d "$VAL_PATH" ] && mv $VAL_PATH/* $OUTPUT_DIR/images/val

    # Remove empty training/val folders
    [ -d "$TRAIN_PATH" ] && rmdir $TRAIN_PATH
    [ -d "$VAL_PATH" ] && rmdir $VAL_PATH

    # Convert the COCO annotations to YOLO format using coco2yolo.py
    echo "  Converting COCO annotations to YOLO format for fold ${OUTPUT_FOLD} and min_area_ratio=${MIN_AREA_RATIO}..."
    uv run python ${COCO_YOLO_SCRIPT_PATH} --json_dir $OUTPUT_DIR

    echo "  Completed processing for min_area_ratio=$MIN_AREA_RATIO."

    # Generate the custom data.yaml file
    DATA_YAML_FILE="$OUTPUT_DIR/mosquito_${OBJECT_NAME}_fold${OUTPUT_FOLD}_${OVERLAP_RATIO//.}.yaml"

    echo "  Creating data.yaml file: $DATA_YAML_FILE"
    cat <<EOL > $DATA_YAML_FILE
path: $(realpath "$OUTPUT_DIR")

train: images/train
val: images/val

nc: 1  # number of classes
names: ['$OBJECT_NAME']  # class names
EOL
  done
  echo "Completed processing for fold $FOLD (output folder fold${OUTPUT_FOLD}."
done

echo "All processes for all folds completed!"