#!/bin/bash

# Set up colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    echo -e "${GREEN}[+] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

print_error() {
    echo -e "${RED}[-] $1${NC}"
}

# Check if Docker is installed
check_docker() {
    print_message "Checking Docker installation..."
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        echo "Visit https://docs.docker.com/get-docker/ for installation instructions."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        echo "Visit https://docs.docker.com/compose/install/ for installation instructions."
        exit 1
    fi
    
    print_message "Docker and Docker Compose are installed."
}

# Detect system architecture
detect_architecture() {
    print_message "Detecting system architecture..."
    ARCH=$(uname -m)
    
    if [ "$ARCH" = "x86_64" ]; then
        print_message "Detected x86_64/AMD64 architecture."
        PLATFORM="linux/amd64"
    elif [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
        print_message "Detected ARM64 architecture."
        PLATFORM="linux/arm64"
        print_warning "Note: Android emulator will not work on ARM architecture."
    else
        print_warning "Unsupported architecture: $ARCH. Defaulting to amd64."
        PLATFORM="linux/amd64"
    fi
    
    export TARGETPLATFORM=$PLATFORM
}

# Check for USB devices
check_usb_devices() {
    print_message "Checking for USB device access..."
    
    if [ "$(id -u)" -ne 0 ]; then
        print_warning "Not running as root. USB device access might be limited."
        print_warning "If you encounter issues, run the following commands:"
        echo "  sudo usermod -aG plugdev \$USER"
        echo "  sudo bash -c 'echo \"SUBSYSTEM==\\\"usb\\\", MODE=\\\"0666\\\"\" > /etc/udev/rules.d/51-android.rules'"
        echo "  sudo udevadm control --reload-rules"
    fi
}

# Build the environment
build_environment() {
    print_message "Building the mobile security testing environment..."
    
    # Create necessary directories if they don't exist
    mkdir -p attacker/{tools,data,scripts/{android,ios,common}}
    mkdir -p defender/{monitor,logs,rules,scripts/{android,ios,common}}
    mkdir -p shared
    
    # Make sure all scripts are executable
    find . -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    
    # Build the containers
    print_message "Building Docker containers (this may take a few minutes)..."
    docker-compose build
    
    if [ $? -eq 0 ]; then
        print_message "Environment built successfully!"
    else
        print_error "Failed to build the environment. Check the error messages above."
        exit 1
    fi
}

# Start the environment
start_environment() {
    print_message "Starting the mobile security testing environment..."
    
    # Ask if user wants to start the Android emulator
    if [ "$PLATFORM" = "linux/amd64" ]; then
        read -p "Do you want to start the Android emulator? (y/n): " start_emulator
        
        if [[ $start_emulator =~ ^[Yy]$ ]]; then
            print_message "Starting environment with Android emulator..."
            docker-compose --profile emulator up -d
        else
            print_message "Starting environment without Android emulator..."
            docker-compose up -d
        fi
    else
        print_warning "Android emulator is not available on $ARCH architecture."
        print_message "Starting environment without Android emulator..."
        docker-compose up -d
    fi
    
    if [ $? -eq 0 ]; then
        print_message "Environment started successfully!"
    else
        print_error "Failed to start the environment. Check the error messages above."
        exit 1
    fi
}

# Display usage information
show_usage() {
    print_message "Mobile Security Testing Environment Setup"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  build    Build the environment"
    echo "  start    Start the environment"
    echo "  stop     Stop the environment"
    echo "  restart  Restart the environment"
    echo "  status   Check the status of the environment"
    echo "  all      Build and start the environment (default)"
    echo ""
}

# Main script execution
if [ $# -eq 0 ]; then
    ACTION="all"
else
    ACTION="$1"
fi

case "$ACTION" in
    build)
        check_docker
        detect_architecture
        build_environment
        ;;
    start)
        check_docker
        detect_architecture
        check_usb_devices
        start_environment
        ;;
    stop)
        print_message "Stopping the environment..."
        docker-compose down
        ;;
    restart)
        print_message "Restarting the environment..."
        docker-compose down
        detect_architecture
        check_usb_devices
        start_environment
        ;;
    status)
        print_message "Checking environment status..."
        docker-compose ps
        ;;
    all)
        check_docker
        detect_architecture
        check_usb_devices
        build_environment
        start_environment
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        print_error "Unknown option: $ACTION"
        show_usage
        exit 1
        ;;
esac

# Display next steps
if [[ "$ACTION" == "all" || "$ACTION" == "start" || "$ACTION" == "restart" ]]; then
    echo ""
    print_message "Next steps:"
    echo "1. Connect your Android or iOS device to your computer"
    echo "2. Access the attacker container:"
    echo "   docker exec -it mobile-attacker bash"
    echo ""
    echo "3. Run the automatic extraction workflow:"
    echo "   /attack/scripts/extract-all.sh"
    echo ""
    echo "4. Access the defender container:"
    echo "   docker exec -it mobile-defender bash"
    echo ""
    echo "5. Run the monitoring script:"
    echo "   /defense/scripts/common/monitor-all.sh"
    echo ""
fi

exit 0 