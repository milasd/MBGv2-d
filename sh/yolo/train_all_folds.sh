# Directory containing all sliced data (folders fold1, ..., fold5; each containing images, .yaml annotations...)
DEFAULT_BASE_DATA_DIR="sahi"
# Directory to save training results
DEFAULT_BASE_RESULTS_DIR="results"
# n. of training runs for each fold
DEFAULT_NUM_RUNS=1
# GPU device ID
DEFAULT_DEVICE_ID=0


show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

For all datasets' .yaml files inside the base data directory (sliced MBGv2), 
train a YOLOv8s model across all 5 folds with customizable parameters.

OPTIONS:
    --data-dir DIR          Path to Base data (sliced MBGv2) directory, which contains fold subdirectories.
    --results-dir DIR       Path to Base results directory (default: $DEFAULT_BASE_RESULTS_DIR).
    --num-runs INT          Number of independent training runs per fold (default: $DEFAULT_NUM_RUNS). 
                              Each training run is independent and starts from the same YOLO pretrained weights.
    --device INT            GPU device ID (0, 1, 2, ...) for training (default: $DEFAULT_DEVICE_ID).
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
    $0
    
    # Custom data directory and number of runs
    $0 --data-dir [path to base data dir] --num-runs 3

    # or

    $0 --data_dir /home/[path to base data dir] --results-dir /home/[path to custom results dir] --num-runs 5 --device 1

EOF
}


BASE_DATA_DIR="$DEFAULT_BASE_DATA_DIR"
BASE_RESULTS_DIR="$DEFAULT_BASE_RESULTS_DIR"
NUM_RUNS="$DEFAULT_NUM_RUNS"
DEVICE_ID="$DEFAULT_DEVICE_ID"

# Parse args
while [[ $# -gt 0 ]]; do
    case $1 in
        --data-dir)
            BASE_DATA_DIR="$2"
            shift 2
            ;;
        --results-dir)
            BASE_RESULTS_DIR="$2"
            shift 2
            ;;
        --num-runs)
            NUM_RUNS="$2"
            shift 2
            ;;
        --device)
            DEVICE_ID="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

[[ ! -d "$BASE_DATA_DIR" ]] && { echo "Error: Data directory '$BASE_DATA_DIR' does not exist"; exit 1; }

[ ! -d "$BASE_RESULTS_DIR" ] && mkdir -p "$BASE_RESULTS_DIR" && echo "Results directory $BASE_RESULTS_DIR created."

# Loop through FOLD values from 1 to 5
for OUTPUT_FOLD in {1..5}; do

  # Log file for this fold
  LOG_FILE="${BASE_RESULTS_DIR}/fold${OUTPUT_FOLD}.log"
  echo "Logging output of fold ${OUTPUT_FOLD} to ${LOG_FILE}..."
  {
    echo "Processing FOLD: $OUTPUT_FOLD"

    ########################
    #### TRAINING: YOLO ####
    ########################

    echo "---------------"
    echo "TRAINING: YOLO"

    # Current fold directory
    DATA_DIR=${BASE_DATA_DIR}/fold${OUTPUT_FOLD}/

    echo "Starting training for all generated data .yaml files in ${DATA_DIR}, fold ${OUTPUT_FOLD}..."

    # Create output directory for current fold
    TRAIN_RESULTS_DIR="${BASE_RESULTS_DIR}/fold${OUTPUT_FOLD}"  
    mkdir -p $TRAIN_RESULTS_DIR

    # Check if any YAML files are found in data directory
    YAML_FILES=$(find "$DATA_DIR" -type f -name "*.yaml" | sort) # Collect all generated data.yaml files from $DATA_DIR

    if [ -z "$YAML_FILES" ]; then
      echo "No .yaml files found in $DATA_DIR. Skipping training."
    else
      echo "Found .yaml files:"
      echo "$YAML_FILES"  

      TRAIN_PY_PATH="MBGv2_dissertation/train.py"  
      TRAIN_COMMAND=""

      for YAML_FILE in $YAML_FILES; do
        TRAIN_COMMAND+="uv run python ${TRAIN_PY_PATH} --data_config $YAML_FILE --out_dir $TRAIN_RESULTS_DIR --n_runs $NUM_RUNS --device $DEVICE_ID && "
      done
      # Remove last trailing '&&'
      TRAIN_COMMAND=${TRAIN_COMMAND%&& }

      echo $TRAIN_COMMAND

      echo "Starting training sequence..."
      eval $TRAIN_COMMAND

      echo "Training process finished for all data .yaml files in ${DATA_DIR}, fold ${OUTPUT_FOLD}."
    fi

    echo "Completed processing for FOLD: $OUTPUT_FOLD"
  } > "$LOG_FILE" 2>&1
done
