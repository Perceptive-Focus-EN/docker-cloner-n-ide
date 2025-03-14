#!/bin/bash

# Set up logging directory
LOG_DIR="/defense/logs/$(date +%Y-%m-%d)"
mkdir -p "$LOG_DIR"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_DIR/monitor.log"
}

# Check for Android devices
check_android() {
    if command -v adb &> /dev/null; then
        adb devices | grep -v "List" | grep -q "device"
        if [ $? -eq 0 ]; then
            log_message "Android device(s) detected"
            /defense/scripts/android/monitor-android.sh &
            return 0
        fi
    fi
    return 1
}

# Check for iOS devices
check_ios() {
    if command -v idevice_id &> /dev/null; then
        idevice_id -l | grep -q "."
        if [ $? -eq 0 ]; then
            log_message "iOS device(s) detected"
            /defense/scripts/ios/monitor-ios.sh &
            return 0
        fi
    fi
    return 1
}

# Main monitoring logic
log_message "Starting device monitoring"

# Check for Android devices
check_android
ANDROID_STATUS=$?

# Check for iOS devices
check_ios
IOS_STATUS=$?

# If no devices found
if [ $ANDROID_STATUS -ne 0 ] && [ $IOS_STATUS -ne 0 ]; then
    log_message "No compatible devices detected"
    exit 1
fi

# Keep the script running
while true; do
    sleep 60
    # Check if devices are still connected
    check_android || log_message "Android device disconnected"
    check_ios || log_message "iOS device disconnected"
done 