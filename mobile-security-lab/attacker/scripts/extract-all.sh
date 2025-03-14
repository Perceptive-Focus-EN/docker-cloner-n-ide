#!/bin/bash

# Set up output directory
OUTPUT_DIR="/attack/data/extraction/$(date +%Y-%m-%d)"
mkdir -p "$OUTPUT_DIR"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$OUTPUT_DIR/extraction.log"
}

log_message "Starting mobile device extraction workflow"

# Check if the detect-device script exists
if [ ! -f "/attack/scripts/common/detect-device.sh" ]; then
    log_message "ERROR: Device detection script not found!"
    exit 1
fi

# Make sure all scripts are executable
chmod +x /attack/scripts/common/detect-device.sh
chmod +x /attack/scripts/android/extract-messages.sh
chmod +x /attack/scripts/ios/extract-ios.sh

# Detect connected devices
log_message "Detecting connected devices..."
DEVICE_TYPE=$(/attack/scripts/common/detect-device.sh)
DETECTION_STATUS=$?

if [ $DETECTION_STATUS -ne 0 ]; then
    log_message "No mobile devices detected. Please connect a device and try again."
    exit 1
fi

log_message "Device type detected: $DEVICE_TYPE"

# Run appropriate extraction scripts based on device type
case "$DEVICE_TYPE" in
    "android")
        log_message "Running Android extraction..."
        /attack/scripts/android/extract-messages.sh
        EXTRACTION_STATUS=$?
        if [ $EXTRACTION_STATUS -ne 0 ]; then
            log_message "Android extraction failed with status $EXTRACTION_STATUS"
            exit $EXTRACTION_STATUS
        fi
        ;;
    "ios")
        log_message "Running iOS extraction..."
        /attack/scripts/ios/extract-ios.sh
        EXTRACTION_STATUS=$?
        if [ $EXTRACTION_STATUS -ne 0 ]; then
            log_message "iOS extraction failed with status $EXTRACTION_STATUS"
            exit $EXTRACTION_STATUS
        fi
        ;;
    "both")
        log_message "Running extraction for both Android and iOS devices..."
        
        # Run Android extraction
        log_message "Starting Android extraction..."
        /attack/scripts/android/extract-messages.sh
        ANDROID_STATUS=$?
        if [ $ANDROID_STATUS -ne 0 ]; then
            log_message "WARNING: Android extraction failed with status $ANDROID_STATUS"
        else
            log_message "Android extraction completed successfully"
        fi
        
        # Run iOS extraction
        log_message "Starting iOS extraction..."
        /attack/scripts/ios/extract-ios.sh
        IOS_STATUS=$?
        if [ $IOS_STATUS -ne 0 ]; then
            log_message "WARNING: iOS extraction failed with status $IOS_STATUS"
        else
            log_message "iOS extraction completed successfully"
        fi
        
        # Check if both extractions failed
        if [ $ANDROID_STATUS -ne 0 ] && [ $IOS_STATUS -ne 0 ]; then
            log_message "ERROR: Both Android and iOS extractions failed"
            exit 1
        fi
        ;;
    *)
        log_message "ERROR: Unknown device type: $DEVICE_TYPE"
        exit 1
        ;;
esac

# Create a summary report
log_message "Creating extraction summary report..."
{
    echo "Mobile Device Extraction Summary"
    echo "================================"
    echo "Date: $(date)"
    echo "Device Type: $DEVICE_TYPE"
    echo ""
    echo "Extraction Results:"
    
    # List Android extraction results if available
    if [ "$DEVICE_TYPE" = "android" ] || [ "$DEVICE_TYPE" = "both" ]; then
        ANDROID_DIR="/attack/data/extraction/android/$(date +%Y-%m-%d)"
        if [ -d "$ANDROID_DIR" ]; then
            echo "Android Extraction:"
            echo "- Location: $ANDROID_DIR"
            if [ -f "$ANDROID_DIR/extraction_report.txt" ]; then
                echo "- Status: Completed"
                echo "- Files extracted: $(find "$ANDROID_DIR" -type f | wc -l)"
            else
                echo "- Status: Incomplete or failed"
            fi
        fi
    fi
    
    # List iOS extraction results if available
    if [ "$DEVICE_TYPE" = "ios" ] || [ "$DEVICE_TYPE" = "both" ]; then
        IOS_DIR="/attack/data/extraction/ios/$(date +%Y-%m-%d)"
        if [ -d "$IOS_DIR" ]; then
            echo "iOS Extraction:"
            echo "- Location: $IOS_DIR"
            if [ -f "$IOS_DIR/extraction_report.txt" ]; then
                echo "- Status: Completed"
                echo "- Files extracted: $(find "$IOS_DIR" -type f | wc -l)"
            else
                echo "- Status: Incomplete or failed"
            fi
        fi
    fi
    
    echo ""
    echo "For detailed information, check the individual extraction reports in each directory."
} > "$OUTPUT_DIR/extraction_summary.txt"

log_message "Extraction workflow completed. Summary saved to $OUTPUT_DIR/extraction_summary.txt"

# Display the summary
cat "$OUTPUT_DIR/extraction_summary.txt" 