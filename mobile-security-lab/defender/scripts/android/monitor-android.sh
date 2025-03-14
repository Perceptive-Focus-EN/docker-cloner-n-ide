#!/bin/bash

# Set up logging directory
LOG_DIR="/defense/logs/$(date +%Y-%m-%d)"
mkdir -p "$LOG_DIR"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_DIR/android-monitor.log"
}

# Function to check for suspicious activities
check_suspicious_activity() {
    # Monitor for new package installations
    adb shell dumpsys package | grep "Package \[.*\]" > "$LOG_DIR/installed_packages.txt"
    
    # Monitor running processes
    adb shell ps > "$LOG_DIR/running_processes.txt"
    
    # Monitor network connections
    adb shell netstat > "$LOG_DIR/network_connections.txt"
    
    # Check for root access
    adb shell su -c "whoami" 2>/dev/null
    if [ $? -eq 0 ]; then
        log_message "WARNING: Device appears to be rooted"
    fi
}

# Function to monitor system logs
monitor_logs() {
    adb logcat | grep -E "SecurityException|Permission denied|SuspiciousActivity" > "$LOG_DIR/security_logs.txt"
}

# Main monitoring loop
log_message "Starting Android device monitoring"

while true; do
    # Check if device is still connected
    if ! adb devices | grep -q "device$"; then
        log_message "Android device disconnected"
        exit 1
    fi
    
    # Perform security checks
    check_suspicious_activity
    
    # Monitor system logs
    monitor_logs
    
    # Wait before next check
    sleep 30
done 