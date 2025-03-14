#!/bin/bash

# Set up logging
LOG_DIR="/attack/data/logs/$(date +%Y-%m-%d)"
mkdir -p "$LOG_DIR"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_DIR/tools-installation.log"
}

log_message "Starting tools installation..."

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    log_message "This script must be run as root"
    echo "This script must be run as root. Try 'sudo $0'"
    exit 1
fi

# Function to install Android tools
install_android_tools() {
    log_message "Installing Android tools..."
    
    # Update package lists
    log_message "Updating package lists..."
    apt-get update
    
    # Install ADB
    if ! command -v adb &> /dev/null; then
        log_message "Installing ADB..."
        apt-get install -y android-tools-adb
        if command -v adb &> /dev/null; then
            log_message "✅ ADB installed successfully"
        else
            log_message "❌ Failed to install ADB"
        fi
    else
        log_message "✅ ADB already installed"
    fi
    
    # Install SQLite
    if ! command -v sqlite3 &> /dev/null; then
        log_message "Installing SQLite..."
        apt-get install -y sqlite3
        if command -v sqlite3 &> /dev/null; then
            log_message "✅ SQLite installed successfully"
        else
            log_message "❌ Failed to install SQLite"
        fi
    else
        log_message "✅ SQLite already installed"
    fi
    
    # Install MVT (Mobile Verification Toolkit) if not already installed
    if ! command -v mvt-android &> /dev/null; then
        log_message "Installing MVT (Mobile Verification Toolkit)..."
        
        # Check if pip is installed
        if ! command -v pip3 &> /dev/null; then
            log_message "Installing pip3..."
            apt-get install -y python3-pip
        fi
        
        # Install MVT
        pip3 install mobile-verification-toolkit
        
        if command -v mvt-android &> /dev/null; then
            log_message "✅ MVT installed successfully"
        else
            log_message "⚠️ MVT installation may have failed. Check manually."
        fi
    else
        log_message "✅ MVT already installed"
    fi
    
    # Start ADB server
    log_message "Starting ADB server..."
    adb start-server
    
    log_message "Android tools installation completed"
}

# Function to install iOS tools
install_ios_tools() {
    log_message "Installing iOS tools..."
    
    # Update package lists
    log_message "Updating package lists..."
    apt-get update
    
    # Install libimobiledevice tools
    if ! command -v idevice_id &> /dev/null; then
        log_message "Installing libimobiledevice tools..."
        apt-get install -y libimobiledevice-utils
        if command -v idevice_id &> /dev/null; then
            log_message "✅ libimobiledevice tools installed successfully"
        else
            log_message "❌ Failed to install libimobiledevice tools"
        fi
    else
        log_message "✅ libimobiledevice tools already installed"
    fi
    
    # Install ideviceinstaller
    if ! command -v ideviceinstaller &> /dev/null; then
        log_message "Installing ideviceinstaller..."
        apt-get install -y ideviceinstaller
        if command -v ideviceinstaller &> /dev/null; then
            log_message "✅ ideviceinstaller installed successfully"
        else
            log_message "❌ Failed to install ideviceinstaller"
        fi
    else
        log_message "✅ ideviceinstaller already installed"
    fi
    
    # Install ifuse (for mounting iOS filesystems)
    if ! command -v ifuse &> /dev/null; then
        log_message "Installing ifuse..."
        apt-get install -y ifuse
        if command -v ifuse &> /dev/null; then
            log_message "✅ ifuse installed successfully"
        else
            log_message "❌ Failed to install ifuse"
        fi
    else
        log_message "✅ ifuse already installed"
    fi
    
    # Install MVT iOS if not already installed
    if ! command -v mvt-ios &> /dev/null; then
        log_message "Installing MVT (Mobile Verification Toolkit) for iOS..."
        
        # Check if pip is installed
        if ! command -v pip3 &> /dev/null; then
            log_message "Installing pip3..."
            apt-get install -y python3-pip
        fi
        
        # Install MVT
        pip3 install mobile-verification-toolkit
        
        if command -v mvt-ios &> /dev/null; then
            log_message "✅ MVT for iOS installed successfully"
        else
            log_message "⚠️ MVT for iOS installation may have failed. Check manually."
        fi
    else
        log_message "✅ MVT for iOS already installed"
    fi
    
    log_message "iOS tools installation completed"
}

# Function to install common tools
install_common_tools() {
    log_message "Installing common tools..."
    
    # Update package lists
    log_message "Updating package lists..."
    apt-get update
    
    # Install Python 3
    if ! command -v python3 &> /dev/null; then
        log_message "Installing Python 3..."
        apt-get install -y python3
        if command -v python3 &> /dev/null; then
            log_message "✅ Python 3 installed successfully"
        else
            log_message "❌ Failed to install Python 3"
        fi
    else
        log_message "✅ Python 3 already installed"
    fi
    
    # Install pip
    if ! command -v pip3 &> /dev/null; then
        log_message "Installing pip3..."
        apt-get install -y python3-pip
        if command -v pip3 &> /dev/null; then
            log_message "✅ pip3 installed successfully"
        else
            log_message "❌ Failed to install pip3"
        fi
    else
        log_message "✅ pip3 already installed"
    fi
    
    # Install other common utilities
    log_message "Installing common utilities..."
    apt-get install -y grep findutils curl wget
    
    log_message "Common tools installation completed"
}

# Function to fix script permissions
fix_script_permissions() {
    log_message "Fixing script permissions..."
    
    # Make all scripts in the scripts directory executable
    find /attack/scripts -type f -name "*.sh" -exec chmod +x {} \;
    
    log_message "Script permissions fixed"
}

# Main installation process
log_message "=== TOOLS INSTALLATION ==="

# Ask what to install
echo "What tools would you like to install?"
echo "1. All tools (Android + iOS)"
echo "2. Android tools only"
echo "3. iOS tools only"
echo "4. Common tools only"
read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        install_common_tools
        install_android_tools
        install_ios_tools
        ;;
    2)
        install_common_tools
        install_android_tools
        ;;
    3)
        install_common_tools
        install_ios_tools
        ;;
    4)
        install_common_tools
        ;;
    *)
        log_message "Invalid choice. Installing all tools by default."
        install_common_tools
        install_android_tools
        install_ios_tools
        ;;
esac

# Fix script permissions
fix_script_permissions

# Verify installation
log_message "=== INSTALLATION VERIFICATION ==="

# Check if verify-tools.sh exists and is executable
if [ -f "/attack/scripts/common/verify-tools.sh" ] && [ -x "/attack/scripts/common/verify-tools.sh" ]; then
    log_message "Running verification script..."
    /attack/scripts/common/verify-tools.sh
    VERIFY_STATUS=$?
    
    if [ $VERIFY_STATUS -eq 0 ]; then
        log_message "✅ Verification passed. Tools are installed correctly."
    else
        log_message "⚠️ Verification found issues. Check the verification log for details."
    fi
else
    log_message "⚠️ Verification script not found or not executable. Skipping verification."
fi

log_message "Tools installation process completed. Check the log for details: $LOG_DIR/tools-installation.log"

# Display a summary
echo "=== INSTALLATION SUMMARY ==="
echo "Installation log: $LOG_DIR/tools-installation.log"
echo ""
echo "To verify the installation, run:"
echo "  /attack/scripts/common/verify-tools.sh"
echo ""
echo "To extract data from connected devices, run:"
echo "  /attack/scripts/extract-all.sh" 