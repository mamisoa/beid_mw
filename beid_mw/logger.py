"""
Logger module for the beid_mw application.

This module sets up logging for the application with appropriate handlers
and formatters.
"""
import os
import sys
import logging
from datetime import datetime

# Configure the logger
def setup_logger(log_level=logging.DEBUG):
    """
    Set up the application logger with console and file handlers.
    
    Args:
        log_level: The logging level to use (default: DEBUG)
        
    Returns:
        A configured logger instance
    """
    # Create logger
    logger = logging.getLogger("beid_mw")
    logger.setLevel(log_level)
    
    # Create formatter
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    # Console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)
    
    # File handler - try multiple directories with fallback
    log_dirs = ["/app", "/tmp", os.path.expanduser("~"), os.getcwd()]
    log_file = None
    
    timestamp = datetime.now().strftime("%Y%m%d")
    
    for log_dir in log_dirs:
        try:
            if not os.path.exists(log_dir):
                os.makedirs(log_dir, exist_ok=True)
                
            test_file = os.path.join(log_dir, f"beid_mw_{timestamp}.log")
            # Test if we can write to this directory
            with open(test_file, 'a') as f:
                f.write("")
                
            log_file = test_file
            logger.info(f"Logger initialized. Log file: {log_file}")
            break
        except (PermissionError, OSError):
            continue
    
    if log_file:
        file_handler = logging.FileHandler(log_file)
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)
    else:
        logger.warning("Could not create log file. Logging to console only.")
    
    return logger

# Create and export the logger instance
logger = setup_logger() 