#!/bin/bash

###########################################
# Docker Cleanup Utility
# Safely cleans up Docker system to free disk space
###########################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to show disk usage
show_disk_usage() {
    echo -e "\n${YELLOW}=== Current Docker Disk Usage ===${NC}"
    docker system df
}

# Function to check if Docker daemon is running
check_docker_daemon() {
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker daemon is not running${NC}"
        echo -e "${YELLOW}💡 Please start Docker Desktop and try again${NC}"
        return 1
    fi
    return 0
}

# Main cleanup function
cleanup_docker() {
    # Check Docker daemon first
    check_docker_daemon || return 1

    # Show current usage
    show_disk_usage

    echo -e "\n${YELLOW}=== Available Cleanup Options ===${NC}"
    echo -e "1. ${GREEN}Safe Cleanup${NC} (Remove unused containers, networks, and dangling images)"
    echo -e "2. ${YELLOW}Moderate Cleanup${NC} (Safe cleanup + remove all unused images)"
    echo -e "3. ${RED}Full Cleanup${NC} (Moderate cleanup + remove all volumes)"
    echo -e "4. Cancel"
    
    read -p "Choose an option (1-4): " choice
    echo

    case "$choice" in
        1)
            echo -e "${YELLOW}Performing safe cleanup...${NC}"
            echo -e "${YELLOW}Stopping unused containers...${NC}"
            docker ps -q | xargs -r docker stop
            
            echo -e "${YELLOW}Removing unused containers...${NC}"
            docker container prune -f
            
            echo -e "${YELLOW}Removing unused networks...${NC}"
            docker network prune -f
            
            echo -e "${YELLOW}Removing dangling images...${NC}"
            docker image prune -f
            ;;
            
        2)
            echo -e "${YELLOW}Performing moderate cleanup...${NC}"
            echo -e "${YELLOW}Stopping all containers...${NC}"
            docker ps -q | xargs -r docker stop
            
            echo -e "${YELLOW}Removing all stopped containers...${NC}"
            docker container prune -f
            
            echo -e "${YELLOW}Removing all unused images...${NC}"
            docker image prune -a -f
            
            echo -e "${YELLOW}Removing unused networks...${NC}"
            docker network prune -f
            ;;
            
        3)
            echo -e "${RED}⚠️  Warning: This will remove ALL unused Docker resources${NC}"
            echo -e "${RED}⚠️  Including volumes that may contain important data${NC}"
            read -p "Are you sure you want to proceed? (y/N): " confirm
            
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                echo -e "${YELLOW}Performing full cleanup...${NC}"
                echo -e "${YELLOW}Stopping all containers...${NC}"
                docker ps -q | xargs -r docker stop
                
                echo -e "${YELLOW}Removing everything unused...${NC}"
                docker system prune -a -f --volumes
            else
                echo -e "${YELLOW}Full cleanup cancelled${NC}"
                return 0
            fi
            ;;
            
        4)
            echo -e "${YELLOW}Cleanup cancelled${NC}"
            return 0
            ;;
            
        *)
            echo -e "${RED}Invalid option${NC}"
            return 1
            ;;
    esac

    # Show space reclaimed
    echo -e "\n${GREEN}=== Cleanup Complete ===${NC}"
    show_disk_usage
}

# Run cleanup if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    cleanup_docker
fi

# Export functions
export -f cleanup_docker
export -f show_disk_usage 