#!/bin/bash

# Set up output directory
OUTPUT_DIR="/attack/data/extraction/ios/$(date +%Y-%m-%d)"
mkdir -p "$OUTPUT_DIR"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Check if device is connected
if ! idevice_id -l | grep -q "."; then
    log_message "No iOS device connected"
    exit 1
fi

# Get device information
log_message "Getting device information..."
ideviceinfo > "$OUTPUT_DIR/device_info.txt"

# Extract system logs
log_message "Extracting system logs..."
idevice_syslog > "$OUTPUT_DIR/system_logs.txt"

# Extract installed applications
log_message "Extracting installed applications list..."
ideviceinstaller -l > "$OUTPUT_DIR/installed_apps.txt"

# Create backup of keychain (requires device to be trusted)
log_message "Attempting to extract keychain data..."
idevicebackup2 backup --full "$OUTPUT_DIR/keychain_backup"

# Extract photos (if device is trusted)
log_message "Attempting to extract photos..."
mkdir -p "$OUTPUT_DIR/photos"
ideviceimagemounter "$OUTPUT_DIR/photos"

# Extract system information
log_message "Extracting system information..."
ideviceinfo | grep -E "DeviceName|ProductType|ProductVersion|BuildVersion" > "$OUTPUT_DIR/system_info.txt"

# Create a summary report
log_message "Creating summary report..."
{
    echo "iOS Device Extraction Report"
    echo "==========================="
    echo "Date: $(date)"
    echo ""
    echo "Files Extracted:"
    echo "- Device information: device_info.txt"
    echo "- System logs: system_logs.txt"
    echo "- Installed applications: installed_apps.txt"
    echo "- Keychain backup: keychain_backup/"
    echo "- Photos: photos/"
    echo "- System information: system_info.txt"
    echo ""
    echo "Location: $OUTPUT_DIR"
} > "$OUTPUT_DIR/extraction_report.txt"

log_message "Extraction complete. Results saved to $OUTPUT_DIR" 