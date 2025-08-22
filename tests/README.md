# MBGv2_dissertation Test Suite

This directory contains comprehensive unit tests for all scripts in the MBGv2_dissertation project.

## Test Structure

### Test Files
- `test_train.py` - Complete tests for `train.py`
- `test_coco2yolo.py` - Complete tests for `coco2yolo.py`
- `test_remove_empty_samples.py` - Complete tests for `remove_empty_samples.py`
- `test_slice_frames.py` - Complete tests for `slice_frames.py`

### Test Runner
- `test_runner.py` - Comprehensive test runner script

## What's Tested

### train.py
- ✅ `calculate_optimal_threshold()` - Threshold calculation logic
- ✅ `process_evaluation_metrics()` - Metrics processing and F1 score analysis
- ✅ `train_and_evaluate()` - Complete training workflow
- ✅ `parse_args()` - Command line argument parsing
- ✅ `main()` - Main function integration
- ✅ Integration tests with realistic data

### coco2yolo.py
- ✅ `convert_coco_json()` - COCO to YOLO format conversion
- ✅ `parse_args()` - Command line argument parsing
- ✅ `main()` - Main function integration
- ✅ Train/val/generic annotation handling
- ✅ Bounding box coordinate conversion
- ✅ Edge cases (crowd annotations, invalid boxes, duplicates)
- ✅ File structure creation
- ✅ Integration tests with realistic datasets

### remove_empty_samples.py
- ✅ `remove_empty_samples()` - Core functionality
- ✅ `parse_arguments()` - Command line argument parsing
- ✅ `main()` - Main function integration
- ✅ File system operations
- ✅ Error handling (missing files/directories)
- ✅ Edge cases (empty folders, malformed JSON)
- ✅ Large dataset simulation
- ✅ Realistic SAHI output cleanup scenarios

### slice_frames.py
- ✅ `parse_arguments()` - Command line argument parsing
- ✅ `main()` - Main function integration
- ✅ SAHI slice function integration
- ✅ Parameter validation and edge cases
- ✅ Realistic dataset scenarios

## Test Categories

### Unit Tests
- Individual function testing
- Parameter validation
- Return value verification
- Error handling

### Integration Tests
- End-to-end workflow testing
- Realistic dataset scenarios
- File system operations
- Cross-module interactions

### Edge Case Tests
- Empty inputs
- Invalid parameters
- Missing files/directories
- Malformed data
- Large datasets

## Running Tests

### Run All Tests
```bash
python tests/test_runner.py
```

### Run Specific Module Tests
```bash
# Train module
pytest tests/test_train.py -v

# COCO to YOLO conversion
pytest tests/test_coco2yolo.py -v

# Empty samples removal
pytest tests/test_remove_empty_samples.py -v

# Frame slicing
pytest tests/test_slice_frames.py -v
```

### Run with Coverage
```bash
pytest --cov=MBGv2_dissertation --cov-report=html tests/
```


## Test Requirements

### Dependencies
- `pytest` - Test framework
- `pytest-cov` - Coverage reporting (optional)
- `unittest.mock` - Mocking framework (built-in)

### Install Test Dependencies
```bash
# Using uv (recommended)
uv sync --group dev

# Using pip
pip install pytest pytest-cov
```

## Test Design Principles

### Comprehensive Coverage
- Every public function is tested
- All code paths are exercised
- Edge cases and error conditions are covered

### Realistic Scenarios
- Tests use realistic data structures
- File system operations are properly mocked
- Integration tests simulate real workflows

### Maintainable Tests
- Simple function-based structure (no classes)
- Clear test names and documentation
- Proper use of fixtures for setup
- Isolated tests that don't depend on each other

### Performance Considerations
- Tests run quickly (< 1 second each)
- Large datasets are simulated, not created
- Proper cleanup of temporary files

## Test Data

### Fixtures
Tests use pytest fixtures to create:
- Sample COCO annotation data
- Temporary directories and files
- Mock objects for external dependencies

### Realistic Data
- COCO annotations with multiple images and objects
- Various image formats and sizes
- Realistic file structures from SAHI output
- Edge cases found in real datasets

## Continuous Integration

These tests are designed to run in CI/CD environments:
- No external dependencies (files, networks)
- Deterministic results
- Clear pass/fail criteria
- Detailed error reporting

## Contributing

When adding new functionality:
1. Add corresponding unit tests
2. Include integration tests for workflows
3. Test edge cases and error conditions
4. Update this README if needed
5. Run the full test suite before submitting

## Coverage Goals

- **Function Coverage**: 100% of public functions tested
- **Line Coverage**: >95% of executable lines
- **Branch Coverage**: >90% of conditional branches
- **Integration Coverage**: All main workflows tested

## Known Limitations

### External Dependencies
- SAHI slice function is mocked (not tested directly)
- YOLO model training is mocked (not tested directly)
- File system operations are tested with temporary directories

### Performance Tests
- No performance benchmarks included
- Memory usage not tested
- Large dataset handling simulated only

### Platform-Specific Tests
- Tests designed for Unix-like systems
- Windows path handling not extensively tested
- GPU-specific functionality mocked