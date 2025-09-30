#!/bin/bash
#####################################
#  DATA PREPROCESSING:
#
#  Slice frames & 
#  generate COCO & YOLO annotations
#  of a MBGv2 object class
#  (watertanks, tire...)
#
#  Customizable script for processing
#  specific folds, dataset splits, and
#  min_area_ratio ranges
#
#####################################

OBJECT_NAME="tire"
SLICE_SIZE=640
OVERLAP_RATIO=0.067

# Default settings, should be overwritten by user.
MBGv2_DIR="data_mosquitoes_v2"
IMAGE_DIR="${MBGv2_DIR}/frames"
ANNOTATIONS_DIR="${MBGv2_DIR}/coco_json_folds/5folds/tire/40m"
BASE_OUT_DIR="MBGv2_sliced"

COCO_YOLO_SCRIPT_PATH="MBGv2_dissertation/data_preprocessing/coco2yolo.py"
REMOVE_EMPTY_SLICES_SCRIPT_PATH="MBGv2_dissertation/data_preprocessing/remove_empty_samples.py"

# Custom parameters
FOLDS=""
SPLITS="train val"
MIN_AREA_RATIOS=""
N_WORKERS=""

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Customizable script for slicing MBGv2 dataset frames containing objects across 
specified folds, dataset splits, and min_area_ratio values.

After the script is finished, the output folder './MBGv2_sliced' will contain
directories for each specified fold. Each fold directory contains 
1 folder for each min_area_ratio value.

Each output min_area_ratio folder contains:

  - images/ and labels/: Directories containing sliced frames for specified splits and YOLO annotations
  - mosquito_{object}_fold{N}_{OVERLAP_RATIO}.yaml: YAML config file for YOLO training with ultralytics
  - coco_format_{split}{fold}_640_{OVERLAP_RATIO}.json: COCO annotations of sliced frames

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
    --folds LIST            Comma-separated list of fold numbers (e.g., "0,1,2" or "0-4" or "1,3" or "1-20")
                               (default: "0-4")
    --splits LIST           Space-separated list of dataset splits to process
                               (e.g., "train", "train val", "train val test")
                               (default: "train val")
    --min-area-ratios LIST  Comma-separated list of min_area_ratio values
                               (e.g., "0.0,0.5,1.0" or "0.0-1.0" or "0.5")
                               (default: "0.0-1.0" in steps of 0.1)
    --n-workers NUM         Number of parallel workers to use for fold processing
                               (default: number of available CPUs, capped at available CPUs)
    --help                  Show this help message and exit

EXAMPLES:
    # Basic usage with mandatory parameters
    \
    $0 --image-dir "./frames" --annotations-dir "./annotations" \\
                --folds "0-20" --splits "train val test" --min-area-ratios "0.0"
    
    # Process folds 0-2 with train and val splits
    \
    $0 --image-dir "./frames" --annotations-dir "./annotations" --object-name "tire" --overlap-ratio 0.067 \\
                --folds "0-2" --splits "train val"
    
    # Process only fold 0 with all splits and specific min_area_ratios
    \
    $0 --image-dir "./frames" --annotations-dir "./annotations" --object-name "watertank" --overlap-ratio 0.1 \\
                --folds "0" --splits "train val test" --min-area-ratios "0.0,0.5,1.0"
    
    # Process folds 1 and 3 with only train split
    \
    $0  --image-dir "/data/frames" --annotations-dir "/data/annotations" --object-name "tire" --overlap-ratio 0.067 \\ 
                --folds "1,3" --splits "train" --min-area-ratios "0.5-0.8"

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

EOF
}

# Function to parse range strings like "0-4", "1,3,5", or "0,2-4"
parse_range() {
    local input="$1"
    local result=""
    
    # Split by comma
    IFS=',' read -ra PARTS <<< "$input"
    for part in "${PARTS[@]}"; do
        if [[ "$part" == *"-"* ]]; then
            # Handle range like "0-4"
            local start=$(echo "$part" | cut -d'-' -f1)
            local end=$(echo "$part" | cut -d'-' -f2)
            for ((i=start; i<=end; i++)); do
                result="$result $i"
            done
        else
            # Handle single value
            result="$result $part"
        fi
    done
    
    echo "$result" | tr ' ' '\n' | sort -n | uniq | tr '\n' ' '
}

# Function to parse min_area_ratio ranges
parse_min_area_ratios() {
    local input="$1"
    local result=""
    
    # Split by comma
    IFS=',' read -ra PARTS <<< "$input"
    for part in "${PARTS[@]}"; do
        if [[ "$part" == *"-"* ]]; then
            # Handle range like "0.0-1.0"
            local start=$(echo "$part" | cut -d'-' -f1)
            local end=$(echo "$part" | cut -d'-' -f2)
            # Generate sequence with 0.1 steps
            local current="$start"
            while (( $(echo "$current <= $end" | bc -l) )); do
                result="$result $current"
                current=$(echo "$current + 0.1" | bc -l)
            done
        else
            # Handle single value
            result="$result $part"
        fi
    done
    
    echo "$result" | tr ' ' '\n' | sort -n | uniq | tr '\n' ' '
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --image-dir)
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
        --slice-size)
            SLICE_SIZE="$2"
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
        --folds)
            FOLDS="$2"
            shift 2
            ;;
        --splits)
            SPLITS="$2"
            shift 2
            ;;
        --min-area-ratios)
            MIN_AREA_RATIOS="$2"
            shift 2
            ;;
        --n-workers)
            N_WORKERS="$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Error: Unknown option $1"
            echo "Use --help for usage information."
            exit 1
            ;;
    esac
done

# Set defaults if not specified
if [[ -z "$FOLDS" ]]; then
    FOLDS="0-4"
fi

if [[ -z "$MIN_AREA_RATIOS" ]]; then
    MIN_AREA_RATIOS="0.0-1.0"
fi

# Set default number of workers to available CPUs
if [[ -z "$N_WORKERS" ]]; then
    N_WORKERS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1)
fi

# Cap N_WORKERS to available CPUs
MAX_CPUS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1)
if [[ $N_WORKERS -gt $MAX_CPUS ]]; then
    echo "Warning: Requested $N_WORKERS workers, but only $MAX_CPUS CPUs available. Using $MAX_CPUS workers."
    N_WORKERS=$MAX_CPUS
fi

# Parse fold range
FOLD_LIST=$(parse_range "$FOLDS")
echo "Processing input folds: $FOLD_LIST"

# Parse min_area_ratio range
MIN_AREA_RATIO_LIST=$(parse_min_area_ratios "$MIN_AREA_RATIOS")
echo "Using min_area_ratios: $MIN_AREA_RATIO_LIST"

# Parse splits
echo "Processing splits: $SPLITS"
echo "Using $N_WORKERS parallel workers"

# Check if output directory exists and creates it if not
[[ ! -d "$BASE_OUT_DIR" ]] && mkdir -p "$BASE_OUT_DIR"

# Check if bc is available for floating point arithmetic
if ! command -v bc &> /dev/null; then
    echo "Error: 'bc' command not found. Please install bc for floating point calculations."
    exit 1
fi

# Function to process a single fold, min_area_ratio, and split combination
process_fold_min_area_ratio_split() {
    local FOLD=$1
    local MIN_AREA_RATIO=$2
    local SPLIT=$3
    
    # Increment fold number by 1 for output directory naming
    OUTPUT_FOLD=$((FOLD + 1))
    
    echo "Processing fold $FOLD (fold${OUTPUT_FOLD}), min_area_ratio=$MIN_AREA_RATIO, split=$SPLIT..."
    
    # Set output directory based on fold number and min_area_ratio
    MIN_AREA_RATIO_TXT="$MIN_AREA_RATIO"
    OUTPUT_DIR="${BASE_OUT_DIR}/${OBJECT_NAME}/fold${OUTPUT_FOLD}/${MIN_AREA_RATIO_TXT//.}"
    
    mkdir -p "$OUTPUT_DIR"
    
    OVERLAP_RATIO_TXT="$OVERLAP_RATIO"
    
    # Construct the JSON path for the current fold and split
    COCO_JSON="${ANNOTATIONS_DIR}/coco_format_${SPLIT}${FOLD}_${OBJECT_NAME}.json"
    
    # Check if JSON file exists
    if [[ ! -f "$COCO_JSON" ]]; then
        echo "  Warning: Annotation file $COCO_JSON not found, skipping..."
        return
    fi

    echo "  Processing with min_area_ratio=$MIN_AREA_RATIO, split=$SPLIT..."

    # Run SAHI coco slice command
    uv run sahi coco slice \
      --ignore_negative_samples \
      --slice_size $SLICE_SIZE \
      --overlap_ratio $OVERLAP_RATIO \
      --min_area_ratio $MIN_AREA_RATIO \
      --output_dir $OUTPUT_DIR \
      --image_dir $IMAGE_DIR \
      --dataset_json_path $COCO_JSON 
      
    SPLIT_FOLDER_NAME=$(basename $COCO_JSON .json)_images_${SLICE_SIZE}_${OVERLAP_RATIO_TXT//.}
    SPLIT_PATH="$OUTPUT_DIR/$SPLIT_FOLDER_NAME"

    SPLIT_JSON_NAME=${SPLIT_FOLDER_NAME//'_images'}.json
    SPLIT_JSON_PATH="$OUTPUT_DIR/$SPLIT_JSON_NAME"

    # Filter slices without any object annotations
    if [[ -f "$SPLIT_JSON_PATH" ]]; then
        uv run python $REMOVE_EMPTY_SLICES_SCRIPT_PATH --images_folder $SPLIT_PATH --coco_annotation_file $SPLIT_JSON_PATH
    fi

    # Create split directory structure
    mkdir -p "$OUTPUT_DIR/images/$SPLIT"

    # Move images to the appropriate split directory
    if [[ -d "$SPLIT_PATH" ]]; then
        mv $SPLIT_PATH/* $OUTPUT_DIR/images/$SPLIT/ 2>/dev/null || true
        rmdir $SPLIT_PATH 2>/dev/null || true
    fi
    
    echo "  Completed processing for fold $FOLD, min_area_ratio=$MIN_AREA_RATIO, split=$SPLIT."
}

# Function to finalize processing for a fold and min_area_ratio (COCO to YOLO conversion and YAML generation)
finalize_fold_min_area_ratio() {
    local FOLD=$1
    local MIN_AREA_RATIO=$2
    
    # Increment fold number by 1 for output directory naming
    OUTPUT_FOLD=$((FOLD + 1))
    
    # Set output directory based on fold number and min_area_ratio
    MIN_AREA_RATIO_TXT="$MIN_AREA_RATIO"
    OUTPUT_DIR="${BASE_OUT_DIR}/${OBJECT_NAME}/fold${OUTPUT_FOLD}/${MIN_AREA_RATIO_TXT//.}"
    
    # Convert the COCO annotations to YOLO format using coco2yolo.py
    echo "  Converting COCO annotations to YOLO format for fold ${OUTPUT_FOLD} and min_area_ratio=${MIN_AREA_RATIO}..."
    uv run python ${COCO_YOLO_SCRIPT_PATH} --json_dir $OUTPUT_DIR

    echo "  Completed COCO to YOLO conversion for min_area_ratio=$MIN_AREA_RATIO."

    # Generate or update the custom data.yaml file
    DATA_YAML_FILE="$OUTPUT_DIR/mosquito_${OBJECT_NAME}_fold${OUTPUT_FOLD}_${OVERLAP_RATIO//.}.yaml"

    if [[ -f "$DATA_YAML_FILE" ]]; then
        echo "  Updating existing data.yaml file: $DATA_YAML_FILE"
        
        # Add new splits to existing YAML file
        for SPLIT in $SPLITS; do
            # Check if this split already exists in the YAML file
            if ! grep -q "^${SPLIT}:" "$DATA_YAML_FILE"; then
                echo "    Adding $SPLIT split to existing YAML"
                # Find the line number where splits end (before 'nc:' line)
                LINE_NUM=$(grep -n "^nc:" "$DATA_YAML_FILE" | cut -d: -f1)
                if [[ -n "$LINE_NUM" ]]; then
                    # Insert the new split before the 'nc:' line
                    sed -i "${LINE_NUM}i\\${SPLIT}: images/${SPLIT}" "$DATA_YAML_FILE"
                else
                    # If no 'nc:' line found, append before the end
                    sed -i "/^names:/i\\${SPLIT}: images/${SPLIT}" "$DATA_YAML_FILE"
                fi
            else
                echo "    Split $SPLIT already exists in YAML file"
            fi
        done
    else
        echo "  Creating new data.yaml file: $DATA_YAML_FILE"
        cat <<EOL > $DATA_YAML_FILE
path: $(realpath "$OUTPUT_DIR")

EOL

        # Add split paths to YAML
        for SPLIT in $SPLITS; do
            echo "$SPLIT: images/$SPLIT" >> $DATA_YAML_FILE
        done

        cat <<EOL >> $DATA_YAML_FILE

nc: 1  # number of classes
names: ['$OBJECT_NAME']  # class names
EOL
    fi
}

# Generate all job combinations for parallel processing
JOBS=()
FOLD_ARRAY=($FOLD_LIST)
SPLIT_ARRAY=($SPLITS)
MIN_AREA_RATIO_ARRAY=($MIN_AREA_RATIO_LIST)

for FOLD in "${FOLD_ARRAY[@]}"; do
    for MIN_AREA_RATIO in "${MIN_AREA_RATIO_ARRAY[@]}"; do
        for SPLIT in "${SPLIT_ARRAY[@]}"; do
            JOBS+=("$FOLD:$MIN_AREA_RATIO:$SPLIT")
        done
    done
done

echo "Generated ${#JOBS[@]} total jobs (${#FOLD_ARRAY[@]} folds × ${#MIN_AREA_RATIO_ARRAY[@]} min_area_ratios × ${#SPLIT_ARRAY[@]} splits)"

# Process all split jobs in parallel first
RUNNING_JOBS=0

for JOB in "${JOBS[@]}"; do
    # Wait if we've reached the maximum number of parallel workers
    while [[ $RUNNING_JOBS -ge $N_WORKERS ]]; do
        # Wait for any background job to complete
        wait -n
        RUNNING_JOBS=$((RUNNING_JOBS - 1))
    done
    
    # Extract fold, min_area_ratio, and split from job string
    FOLD=$(echo $JOB | cut -d: -f1)
    MIN_AREA_RATIO=$(echo $JOB | cut -d: -f2)
    SPLIT=$(echo $JOB | cut -d: -f3)
    
    # Start processing in background
    process_fold_min_area_ratio_split $FOLD $MIN_AREA_RATIO $SPLIT &
    RUNNING_JOBS=$((RUNNING_JOBS + 1))
done

# Wait for all split processing to complete
wait

# Generate finalization jobs for COCO to YOLO conversion and YAML generation
FINALIZE_JOBS=()
for FOLD in "${FOLD_ARRAY[@]}"; do
    for MIN_AREA_RATIO in "${MIN_AREA_RATIO_ARRAY[@]}"; do
        FINALIZE_JOBS+=("$FOLD:$MIN_AREA_RATIO")
    done
done

echo "Processing ${#FINALIZE_JOBS[@]} finalization jobs (COCO to YOLO conversion and YAML generation)..."

# Process finalization jobs in parallel
RUNNING_JOBS=0

for JOB in "${FINALIZE_JOBS[@]}"; do
    # Wait if we've reached the maximum number of parallel workers
    while [[ $RUNNING_JOBS -ge $N_WORKERS ]]; do
        # Wait for any background job to complete
        wait -n
        RUNNING_JOBS=$((RUNNING_JOBS - 1))
    done
    
    # Extract fold and min_area_ratio from job string
    FOLD=$(echo $JOB | cut -d: -f1)
    MIN_AREA_RATIO=$(echo $JOB | cut -d: -f2)
    
    # Start finalization processing in background
    finalize_fold_min_area_ratio $FOLD $MIN_AREA_RATIO &
    RUNNING_JOBS=$((RUNNING_JOBS + 1))
done

# Wait for all finalization jobs to complete
wait

echo "All processes for specified folds completed!"