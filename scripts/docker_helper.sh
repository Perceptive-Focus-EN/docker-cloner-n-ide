1-4 is. #!/bin/bash

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

# Function to check Docker Desktop status on macOS
check_docker_status_macos() {
    if [ ! -d "/Applications/Docker.app" ]; then
        echo "not_installed"
        return
    fi
    
    if pgrep -x "Docker" >/dev/null; then
        if docker info >/dev/null 2>&1; then
            echo "running"
        else
            echo "starting"
        fi
    else
        echo "stopped"
    fi
}

# Function to start Docker Desktop on macOS
start_docker_macos() {
    echo -e "${YELLOW}🐳 Starting Docker Desktop...${NC}"
    
    # First try opening Docker.app
    open -a Docker
    
    # Wait for Docker to start
    echo -e "${YELLOW}⏳ Waiting for Docker to start (this may take a minute)...${NC}"
    local attempts=0
    while [ $attempts -lt 60 ]; do
        if docker info >/dev/null 2>&1; then
            echo -e "\n${GREEN}✅ Docker Desktop is now running!${NC}"
            return 0
        fi
        sleep 2
        ((attempts++))
        echo -n "."
    done
    
    # If Docker still isn't running, try AppleScript
    if [ $attempts -eq 60 ]; then
        echo -e "\n${YELLOW}⚠️ Docker Desktop is taking longer than usual to start. Trying alternative method...${NC}"
        osascript <<EOF
            tell application "Docker"
                activate
            end tell
EOF
        
        # Wait another 30 seconds
        attempts=0
        while [ $attempts -lt 15 ]; do
            if docker info >/dev/null 2>&1; then
                echo -e "\n${GREEN}✅ Docker Desktop is now running!${NC}"
                return 0
            fi
            sleep 2
            ((attempts++))
            echo -n "."
        done
    fi
    
    echo -e "\n${RED}❌ Docker Desktop did not start properly${NC}"
    echo -e "${YELLOW}💡 Please try starting Docker Desktop manually${NC}"
    return 1
}

# Main function to manage Docker
manage_docker() {
    local os_type=$(get_os_type)
    
    case $os_type in
        "macos")
            local status=$(check_docker_status_macos)
            case $status in
                "not_installed")
                    echo -e "${RED}❌ Docker Desktop is not installed${NC}"
                    echo -e "${YELLOW}💡 Install Docker Desktop from:${NC}"
                    echo "   https://www.docker.com/products/docker-desktop"
                    echo -e "${YELLOW}💡 Or install with Homebrew:${NC}"
                    echo "   brew install --cask docker"
                    return 1
                    ;;
                "stopped")
                    echo -e "${YELLOW}🔍 Docker Desktop is installed but not running${NC}"
                    read -p "Would you like to start Docker Desktop now? (y/n): " start_docker
                    if [ "$start_docker" = "y" ]; then
                        start_docker_macos || return 1
                    else
                        echo -e "${YELLOW}💡 Start Docker Desktop manually when ready${NC}"
                        return 1
                    fi
                    ;;
                "starting")
                    echo -e "${YELLOW}⏳ Docker Desktop is already starting...${NC}"
                    echo -e "${YELLOW}💡 Please wait for it to finish starting${NC}"
                    local attempts=0
                    while [ $attempts -lt 30 ]; do
                        if docker info >/dev/null 2>&1; then
                            echo -e "${GREEN}✅ Docker Desktop is now running!${NC}"
                            return 0
                        fi
                        sleep 2
                        ((attempts++))
                        echo -n "."
                    done
                    echo -e "\n${RED}❌ Docker Desktop did not start properly${NC}"
                    return 1
                    ;;
                "running")
                    echo -e "${GREEN}✅ Docker Desktop is running${NC}"
                    return 0
                    ;;
            esac
            ;;
        "linux")
            if ! command -v docker >/dev/null 2>&1; then
                echo -e "${RED}❌ Docker is not installed${NC}"
                echo -e "${YELLOW}💡 Install Docker using:${NC}"
                echo "   curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh"
                return 1
            elif systemctl is-active docker >/dev/null 2>&1; then
                echo -e "${GREEN}✅ Docker daemon is running${NC}"
                return 0
            else
                echo -e "${YELLOW}🔍 Docker daemon is not running${NC}"
                read -p "Would you like to start Docker daemon now? (y/n): " start_docker
                if [ "$start_docker" = "y" ]; then
                    echo -e "${YELLOW}Starting Docker daemon...${NC}"
                    sudo systemctl start docker || {
                        echo -e "${RED}❌ Failed to start Docker daemon${NC}"
                        return 1
                    }
                    echo -e "${GREEN}✅ Docker daemon is now running${NC}"
                    return 0
                fi
                return 1
            fi
            ;;
        "windows")
            if ! command -v docker >/dev/null 2>&1; then
                echo -e "${RED}❌ Docker Desktop is not installed${NC}"
                echo -e "${YELLOW}💡 Install Docker Desktop from:${NC}"
                echo "   https://www.docker.com/products/docker-desktop"
                return 1
            elif docker info >/dev/null 2>&1; then
                echo -e "${GREEN}✅ Docker Desktop is running${NC}"
                return 0
            else
                echo -e "${YELLOW}🔍 Docker Desktop is not running${NC}"
                read -p "Would you like to start Docker Desktop now? (y/n): " start_docker
                if [ "$start_docker" = "y" ]; then
                    echo -e "${YELLOW}Starting Docker Desktop...${NC}"
                    "/c/Program Files/Docker/Docker/Docker Desktop.exe" &
                    local attempts=0
                    while [ $attempts -lt 30 ]; do
                        if docker info >/dev/null 2>&1; then
                            echo -e "${GREEN}✅ Docker Desktop is now running!${NC}"
                            return 0
                        fi
                        sleep 2
                        ((attempts++))
                        echo -n "."
                    done
                    echo -e "\n${RED}❌ Docker Desktop did not start properly${NC}"
                fi
                return 1
            fi
            ;;
        *)
            echo -e "${RED}❌ Unsupported operating system${NC}"
            return 1
            ;;
    esac
}

# Run the main function
manage_docker 