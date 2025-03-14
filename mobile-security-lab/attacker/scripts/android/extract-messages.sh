#!/bin/bash

# Set up output directory
OUTPUT_DIR="/attack/data/extraction/android/$(date +%Y-%m-%d)"
mkdir -p "$OUTPUT_DIR"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Check if device is connected
if ! adb devices | grep -q "device$"; then
    log_message "No Android device connected"
    exit 1
fi

# Create backup of messages
log_message "Creating backup of messages..."
adb shell "run-as com.android.providers.telephony cp /data/data/com.android.providers.telephony/databases/mmssms.db /sdcard/mmssms.db"
adb pull /sdcard/mmssms.db "$OUTPUT_DIR/mmssms.db"

# Extract contacts
log_message "Extracting contacts..."
adb shell "run-as com.android.providers.contacts cp /data/data/com.android.providers.contacts/databases/contacts2.db /sdcard/contacts2.db"
adb pull /sdcard/contacts2.db "$OUTPUT_DIR/contacts2.db"

# Extract call history
log_message "Extracting call history..."
adb shell "run-as com.android.providers.contacts cp /data/data/com.android.providers.contacts/databases/calllog.db /sdcard/calllog.db"
adb pull /sdcard/calllog.db "$OUTPUT_DIR/calllog.db"

# Extract installed applications
log_message "Extracting installed applications list..."
adb shell pm list packages > "$OUTPUT_DIR/installed_apps.txt"

# Extract system information
log_message "Extracting system information..."
adb shell getprop > "$OUTPUT_DIR/system_properties.txt"

# Clean up temporary files on device
adb shell rm /sdcard/mmssms.db /sdcard/contacts2.db /sdcard/calllog.db

# Create a summary report
log_message "Creating summary report..."
{
    echo "Android Device Extraction Report"
    echo "==============================="
    echo "Date: $(date)"
    echo ""
    echo "Files Extracted:"
    echo "- Messages database: mmssms.db"
    echo "- Contacts database: contacts2.db"
    echo "- Call history: calllog.db"
    echo "- Installed applications: installed_apps.txt"
    echo "- System properties: system_properties.txt"
    echo ""
    echo "Location: $OUTPUT_DIR"
} > "$OUTPUT_DIR/extraction_report.txt"

log_message "Extraction complete. Results saved to $OUTPUT_DIR" 