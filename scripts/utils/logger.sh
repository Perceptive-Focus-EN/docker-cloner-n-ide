#!/bin/bash

# Logger utility for consistent logging across the application

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Log levels as integers
LOG_LEVEL_DEBUG=0
LOG_LEVEL_INFO=1
LOG_LEVEL_WARNING=2
LOG_LEVEL_ERROR=3
LOG_LEVEL_SUCCESS=4

# Default log level (can be overridden by setting LOG_LEVEL environment variable)
# Make sure LOG_LEVEL is an integer
if [[ -n "$LOG_LEVEL" && "$LOG_LEVEL" =~ ^[0-9]+$ ]]; then
    # Use the environment variable if it's set and is a number
    :
else
    # Otherwise, default to INFO level
    LOG_LEVEL=$LOG_LEVEL_INFO
fi

# Function to log debug messages
log_debug() {
    if [ $LOG_LEVEL -le $LOG_LEVEL_DEBUG ]; then
        echo -e "${CYAN}[DEBUG] $*${NC}"
    fi
}

# Function to log info messages
log_info() {
    if [ $LOG_LEVEL -le $LOG_LEVEL_INFO ]; then
        echo -e "${BLUE}[INFO] $*${NC}"
    fi
}

# Function to log warning messages
log_warning() {
    if [ $LOG_LEVEL -le $LOG_LEVEL_WARNING ]; then
        echo -e "${YELLOW}[WARNING] $*${NC}"
    fi
}

# Function to log error messages
log_error() {
    if [ $LOG_LEVEL -le $LOG_LEVEL_ERROR ]; then
        echo -e "${RED}[ERROR] $*${NC}" >&2
    fi
}

# Function to log success messages
log_success() {
    if [ $LOG_LEVEL -le $LOG_LEVEL_SUCCESS ]; then
        echo -e "${GREEN}[SUCCESS] $*${NC}"
    fi
}

# Function to log a section header
log_section() {
    echo -e "${MAGENTA}=== $* ===${NC}"
}

# Function to log a command execution
log_cmd() {
    local cmd="$1"
    local description="$2"
    
    echo -e "${YELLOW}[EXEC] ${description:-Running command}:${NC} $cmd"
    eval "$cmd"
    local status=$?
    
    if [ $status -eq 0 ]; then
        log_success "Command completed successfully"
    else
        log_error "Command failed with status $status"
    fi
    
    return $status
}

# Function to log a step in a process
log_step() {
    local step_number="$1"
    local step_description="$2"
    
    echo -e "${BLUE}[$step_number] ${step_description}${NC}"
}

# Function to log a progress message
log_progress() {
    local progress="$1"
    local total="$2"
    local description="$3"
    
    local percentage=$((progress * 100 / total))
    echo -e "${CYAN}[PROGRESS] ${description:-Progress}: $progress/$total ($percentage%)${NC}"
}

# Export functions
export -f log_debug
export -f log_info
export -f log_warning
export -f log_error
export -f log_success
export -f log_section
export -f log_cmd
export -f log_step
export -f log_progress 