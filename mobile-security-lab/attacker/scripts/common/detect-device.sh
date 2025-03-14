#!/bin/bash

# Set up logging
LOG_DIR="/attack/data/logs/$(date +%Y-%m-%d)"
mkdir -p "$LOG_DIR"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_DIR/device-detection.log"
}

log_message "Starting device detection..."

# Check for Android devices
check_android() {
    if command -v adb &> /dev/null; then
        # Get list of connected devices
        DEVICES=$(adb devices | grep -v "List" | grep "device$" | cut -f1)
        if [ -n "$DEVICES" ]; then
            log_message "Android device(s) detected:"
            echo "$DEVICES" | while read -r device; do
                MODEL=$(adb -s "$device" shell getprop ro.product.model 2>/dev/null)
                ANDROID_VER=$(adb -s "$device" shell getprop ro.build.version.release 2>/dev/null)
                log_message "  - $device: $MODEL (Android $ANDROID_VER)"
            done
            return 0
        fi
    else
        log_message "ADB not found. Cannot check for Android devices."
    fi
    return 1
}

# Check for iOS devices
check_ios() {
    if command -v idevice_id &> /dev/null; then
        # Get list of connected devices
        DEVICES=$(idevice_id -l)
        if [ -n "$DEVICES" ]; then
            log_message "iOS device(s) detected:"
            echo "$DEVICES" | while read -r device; do
                if command -v ideviceinfo &> /dev/null; then
                    MODEL=$(ideviceinfo -u "$device" | grep "ProductType" | cut -d: -f2- | tr -d ' ' 2>/dev/null)
                    IOS_VER=$(ideviceinfo -u "$device" | grep "ProductVersion" | cut -d: -f2- | tr -d ' ' 2>/dev/null)
                    log_message "  - $device: $MODEL (iOS $IOS_VER)"
                else
                    log_message "  - $device: (ideviceinfo not available for details)"
                fi
            done
            return 0
        fi
    else
        log_message "libimobiledevice tools not found. Cannot check for iOS devices."
    fi
    return 1
}

# Check for both types of devices
ANDROID_CONNECTED=false
IOS_CONNECTED=false

# Check Android
if check_android; then
    ANDROID_CONNECTED=true
fi

# Check iOS
if check_ios; then
    IOS_CONNECTED=true
fi

# Return results
if [ "$ANDROID_CONNECTED" = true ] && [ "$IOS_CONNECTED" = true ]; then
    log_message "Both Android and iOS devices detected"
    echo "both"
    exit 0
elif [ "$ANDROID_CONNECTED" = true ]; then
    log_message "Only Android devices detected"
    echo "android"
    exit 0
elif [ "$IOS_CONNECTED" = true ]; then
    log_message "Only iOS devices detected"
    echo "ios"
    exit 0
else
    log_message "No mobile devices detected"
    echo "none"
    exit 1
fi 