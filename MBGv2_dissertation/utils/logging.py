"""
Centralized logging configuration for MBGv2_dissertation.

This module provides a consistent logging setup across all scripts in the project.
"""

import logging
import sys

from pathlib import Path
from typing import Optional


def _setup_logger(
    name: str,
    level: int = logging.INFO,
    format_string: Optional[str] = None,
    log_file: Optional[Path] = None,
) -> logging.Logger:
    """
    Set up a logger with consistent formatting and configuration.

    Args:
        name: Name of the logger (typically __name__)
        level: Logging level (default: INFO)
        format_string: Custom format string (optional)
        log_file: Path to log file (optional, logs to console if None)

    Returns:
        Configured logger instance
    """
    if format_string is None:
        format_string = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"

    logger = logging.getLogger(name)
    logger.setLevel(level)

    if logger.handlers:
        return logger

    formatter = logging.Formatter(format_string)

    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(level)
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)

    if log_file:
        file_handler = logging.FileHandler(log_file)
        file_handler.setLevel(level)
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)

    return logger


def get_logger(name: str) -> logging.Logger:
    """
    Get a simple logger with minimal formatting for clean output.

    Args:
        name: Name of the logger

    Returns:
        Logger with simple message-only formatting
    """
    return _setup_logger(
        name=name,
        level=logging.INFO,
        format_string="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    )
