#!/bin/bash

# Set up logging
LOG_DIR="/attack/data/logs/$(date +%Y-%m-%d)"
mkdir -p "$LOG_DIR"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_DIR/tools-verification.log"
}

log_message "Starting tools verification..."

# Check Android tools
check_android_tools() {
    log_message "Checking Android tools..."
    
    # Check ADB
    if command -v adb &> /dev/null; then
        ADB_VERSION=$(adb version | head -1)
        log_message "✅ ADB found: $ADB_VERSION"
    else
        log_message "❌ ADB not found. Android extraction will not work."
        return 1
    fi
    
    # Check if ADB server is running
    adb start-server &> /dev/null
    if [ $? -eq 0 ]; then
        log_message "✅ ADB server started successfully"
    else
        log_message "⚠️ Warning: Could not start ADB server. Check USB permissions."
    fi
    
    # Check for Android-specific extraction tools
    if command -v sqlite3 &> /dev/null; then
        SQLITE_VERSION=$(sqlite3 --version)
        log_message "✅ SQLite found: $SQLITE_VERSION"
    else
        log_message "⚠️ Warning: SQLite not found. Database extraction may be limited."
    fi
    
    # Check for MVT (Mobile Verification Toolkit) if it should be available
    if command -v mvt-android &> /dev/null; then
        MVT_VERSION=$(mvt-android --version 2>/dev/null || echo "version unknown")
        log_message "✅ MVT-Android found: $MVT_VERSION"
    else
        log_message "⚠️ Warning: MVT-Android not found. Advanced forensics capabilities will be limited."
    fi
    
    return 0
}

# Check iOS tools
check_ios_tools() {
    log_message "Checking iOS tools..."
    
    # Check libimobiledevice tools
    TOOLS_MISSING=0
    
    # Check idevice_id
    if command -v idevice_id &> /dev/null; then
        log_message "✅ idevice_id found"
    else
        log_message "❌ idevice_id not found. iOS device detection will not work."
        TOOLS_MISSING=$((TOOLS_MISSING+1))
    fi
    
    # Check ideviceinfo
    if command -v ideviceinfo &> /dev/null; then
        log_message "✅ ideviceinfo found"
    else
        log_message "❌ ideviceinfo not found. iOS device information retrieval will not work."
        TOOLS_MISSING=$((TOOLS_MISSING+1))
    fi
    
    # Check ideviceinstaller
    if command -v ideviceinstaller &> /dev/null; then
        log_message "✅ ideviceinstaller found"
    else
        log_message "❌ ideviceinstaller not found. iOS app listing will not work."
        TOOLS_MISSING=$((TOOLS_MISSING+1))
    fi
    
    # Check idevicebackup2
    if command -v idevicebackup2 &> /dev/null; then
        log_message "✅ idevicebackup2 found"
    else
        log_message "❌ idevicebackup2 not found. iOS backup creation will not work."
        TOOLS_MISSING=$((TOOLS_MISSING+1))
    fi
    
    # Check idevice_syslog
    if command -v idevice_syslog &> /dev/null; then
        log_message "✅ idevice_syslog found"
    else
        log_message "❌ idevice_syslog not found. iOS system log extraction will not work."
        TOOLS_MISSING=$((TOOLS_MISSING+1))
    fi
    
    # Check for MVT iOS if it should be available
    if command -v mvt-ios &> /dev/null; then
        MVT_VERSION=$(mvt-ios --version 2>/dev/null || echo "version unknown")
        log_message "✅ MVT-iOS found: $MVT_VERSION"
    else
        log_message "⚠️ Warning: MVT-iOS not found. Advanced iOS forensics capabilities will be limited."
    fi
    
    if [ $TOOLS_MISSING -gt 0 ]; then
        log_message "❌ $TOOLS_MISSING iOS tools are missing. iOS extraction will be limited or not work."
        return 1
    fi
    
    return 0
}

# Check common tools
check_common_tools() {
    log_message "Checking common tools..."
    
    # Check for Python
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version)
        log_message "✅ Python found: $PYTHON_VERSION"
    else
        log_message "⚠️ Warning: Python 3 not found. Some scripts may not work."
    fi
    
    # Check for grep
    if command -v grep &> /dev/null; then
        log_message "✅ grep found"
    else
        log_message "❌ grep not found. This is a critical dependency."
        return 1
    fi
    
    # Check for find
    if command -v find &> /dev/null; then
        log_message "✅ find found"
    else
        log_message "❌ find not found. This is a critical dependency."
        return 1
    fi
    
    return 0
}

# Check script permissions
check_script_permissions() {
    log_message "Checking script permissions..."
    
    SCRIPTS=(
        "/attack/scripts/common/detect-device.sh"
        "/attack/scripts/android/extract-messages.sh"
        "/attack/scripts/ios/extract-ios.sh"
        "/attack/scripts/extract-all.sh"
    )
    
    for script in "${SCRIPTS[@]}"; do
        if [ -f "$script" ]; then
            if [ -x "$script" ]; then
                log_message "✅ $script is executable"
            else
                log_message "❌ $script is not executable. Attempting to fix..."
                chmod +x "$script"
                if [ -x "$script" ]; then
                    log_message "✅ Fixed permissions for $script"
                else
                    log_message "❌ Failed to fix permissions for $script"
                fi
            fi
        else
            log_message "❌ $script not found"
        fi
    done
}

# Run all checks
log_message "=== TOOL VERIFICATION REPORT ==="

# Check common tools first
check_common_tools
COMMON_STATUS=$?

# Check Android tools
check_android_tools
ANDROID_STATUS=$?

# Check iOS tools
check_ios_tools
IOS_STATUS=$?

# Check script permissions
check_script_permissions

# Generate summary
log_message "=== VERIFICATION SUMMARY ==="
if [ $COMMON_STATUS -eq 0 ]; then
    log_message "✅ Common tools: All critical tools available"
else
    log_message "❌ Common tools: Some critical tools missing"
fi

if [ $ANDROID_STATUS -eq 0 ]; then
    log_message "✅ Android tools: Basic extraction should work"
else
    log_message "⚠️ Android tools: Extraction may be limited"
fi

if [ $IOS_STATUS -eq 0 ]; then
    log_message "✅ iOS tools: Basic extraction should work"
else
    log_message "⚠️ iOS tools: Extraction may be limited"
fi

# Provide recommendations
log_message "=== RECOMMENDATIONS ==="
if [ $ANDROID_STATUS -ne 0 ] || [ $IOS_STATUS -ne 0 ]; then
    log_message "To install missing tools, you may need to run:"
    
    if [ $ANDROID_STATUS -ne 0 ]; then
        log_message "  For Android tools: apt-get update && apt-get install -y adb sqlite3"
    fi
    
    if [ $IOS_STATUS -ne 0 ]; then
        log_message "  For iOS tools: apt-get update && apt-get install -y libimobiledevice-utils ideviceinstaller"
    fi
fi

log_message "Verification completed. Check the log for details: $LOG_DIR/tools-verification.log"

# Return overall status
if [ $COMMON_STATUS -eq 0 ] && ([ $ANDROID_STATUS -eq 0 ] || [ $IOS_STATUS -eq 0 ]); then
    log_message "✅ System is ready for at least one type of device extraction"
    exit 0
else
    log_message "❌ System is not properly configured for extraction"
    exit 1
fi 