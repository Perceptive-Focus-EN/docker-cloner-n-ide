#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check OS type
get_os_type() {
    case "$OSTYPE" in
        darwin*)  echo "macos" ;;
        linux*)   echo "linux" ;;
        msys*|cygwin*) echo "windows" ;;
        *)        echo "unknown" ;;
    esac
}

# Function to check required tools
check_required_tools() {
    local missing_tools=()
    
    # Check for git
    if ! command -v git >/dev/null 2>&1; then
        missing_tools+=("git")
    fi
    
    # Check for docker
    if ! command -v docker >/dev/null 2>&1; then
        missing_tools+=("docker")
    fi
    
    # Check for curl
    if ! command -v curl >/dev/null 2>&1; then
        missing_tools+=("curl")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "${RED}❌ Missing required tools: ${missing_tools[*]}${NC}"
        echo -e "${YELLOW}💡 Please install the missing tools and try again${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ All required tools are installed${NC}"
    return 0
}

# Function to check Python environment
check_python_env() {
    # Check for Python
    if ! command -v python3 >/dev/null 2>&1; then
        echo -e "${RED}❌ Python 3 is not installed${NC}"
        echo -e "${YELLOW}💡 Please install Python 3 from:${NC}"
        echo "   https://www.python.org/downloads/"
        return 1
    fi
    
    # Check for pip
    if ! command -v pip3 >/dev/null 2>&1; then
        echo -e "${RED}❌ pip3 is not installed${NC}"
        echo -e "${YELLOW}💡 Please install pip3${NC}"
        return 1
    fi
    
    # Check for virtual environment
    if [ -z "$VIRTUAL_ENV" ]; then
        echo -e "${YELLOW}⚠️ No virtual environment activated${NC}"
        if [ -d "venv" ]; then
            echo -e "${YELLOW}💡 Found existing venv, activating...${NC}"
            source venv/bin/activate
        else
            echo -e "${YELLOW}💡 Creating new virtual environment...${NC}"
            python3 -m venv venv
            source venv/bin/activate
        fi
    fi
    
    echo -e "${GREEN}✅ Python environment is ready${NC}"
    return 0
}

# Function to check network connectivity
check_network() {
    if ! ping -c 1 github.com >/dev/null 2>&1; then
        echo -e "${RED}❌ No network connection${NC}"
        echo -e "${YELLOW}💡 Please check your internet connection${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Network connection is available${NC}"
    return 0
}

# Main environment check function
check_environment() {
    echo -e "${YELLOW}🔍 Checking environment...${NC}"
    
    # Get OS type
    OS_TYPE=$(get_os_type)
    echo -e "${YELLOW}📌 Detected OS: $OS_TYPE${NC}"
    
    # Run all checks
    check_required_tools || return 1
    check_python_env || return 1
    check_network || return 1
    
    echo -e "${GREEN}✅ Environment check completed successfully${NC}"
    return 0
}

# Export functions
export -f get_os_type
export -f check_required_tools
export -f check_python_env
export -f check_network
export -f check_environment 