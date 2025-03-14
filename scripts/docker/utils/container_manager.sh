#!/bin/bash

###########################################
# Container Manager Utility
# Standalone utility for Docker container operations
# No dependencies on other scripts
#
# Provides:
# - list_containers()
# - remove_container()
# - rename_container()
# - handle_container_conflict()
# - container_exists()
# - get_container_status()
# - is_container_running()
###########################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to list all containers
list_containers() {
    echo -e "${YELLOW}📋 Listing all containers...${NC}"
    docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.ID}}"
}

# Function to remove container
remove_container() {
    local container_name="$1"
    
    echo -e "${YELLOW}🗑️ Removing container ${container_name}...${NC}"
    if docker rm -f "$container_name" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Container removed successfully${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to remove container${NC}"
        return 1
    fi
}

# Function to rename container
rename_container() {
    local old_name="$1"
    local new_name="$2"
    
    echo -e "${YELLOW}✏️ Renaming container ${old_name} to ${new_name}...${NC}"
    if docker rename "$old_name" "$new_name"; then
        echo -e "${GREEN}✅ Container renamed successfully${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to rename container${NC}"
        return 1
    fi
}

# Function to handle container name conflict
handle_container_conflict() {
    local container_name="$1"
    
    # Show header
    echo -e "\n${YELLOW}=== Container Conflict Resolution ===${NC}"
    echo -e "${YELLOW}⚠️  Container ${container_name} already exists${NC}"
    
    # Show current containers first
    echo -e "\n${GREEN}Current Docker Containers:${NC}"
    echo -e "${YELLOW}------------------------${NC}"
    list_containers
    
    # Show all available options
    echo -e "\n${GREEN}Available Options:${NC}"
    echo -e "${YELLOW}----------------${NC}"
    echo -e "${GREEN}1.${NC} Remove existing container ${container_name}"
    echo -e "${GREEN}2.${NC} Rename existing container"
    echo -e "${GREEN}3.${NC} Auto-generate new unique name"
    echo -e "${RED}4.${NC} Cancel operation"
    
    # Now ask for input
    echo -e "\n${YELLOW}What would you like to do?${NC}"
    while true; do
        read -p "Choose an option (1-4): " choice
        echo
        
        case "$choice" in
            1)
                echo -e "${YELLOW}🗑️  Removing container ${container_name}...${NC}"
                if remove_container "$container_name"; then
                    return 0
                else
                    return 1
                fi
                ;;
            2)
                while true; do
                    read -p "Enter new name for the existing container: " new_name
                    if [[ -z "$new_name" ]]; then
                        echo -e "${RED}Error: Name cannot be empty${NC}"
                        continue
                    fi
                    if container_exists "$new_name"; then
                        echo -e "${RED}Error: Container ${new_name} already exists${NC}"
                        continue
                    fi
                    break
                done
                
                echo -e "${YELLOW}✏️  Renaming container ${container_name} to ${new_name}...${NC}"
                if rename_container "$container_name" "$new_name"; then
                    return 0
                else
                    return 1
                fi
                ;;
            3)
                local counter=1
                local new_name
                while true; do
                    new_name="${container_name}_${counter}"
                    if ! container_exists "$new_name"; then
                        echo -e "${GREEN}✅ Generated unique name: ${new_name}${NC}"
                        echo "$new_name"
                        return 0
                    fi
                    ((counter++))
                done
                ;;
            4)
                echo -e "${YELLOW}Operation cancelled by user${NC}"
                return 1
                ;;
            *)
                echo -e "${RED}Invalid input: Please enter a number between 1 and 4${NC}"
                ;;
        esac
    done
}

# Function to check container exists
container_exists() {
    local container_name="$1"
    docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"
}

# Function to get container status
get_container_status() {
    local container_name="$1"
    docker ps -a --filter "name=^/${container_name}$" --format "{{.Status}}"
}

# Function to check if container is running
is_container_running() {
    local container_name="$1"
    docker ps --filter "name=^/${container_name}$" --format "{{.Names}}" | grep -q "^${container_name}$"
}

# Export functions
export -f list_containers
export -f remove_container
export -f rename_container
export -f handle_container_conflict
export -f container_exists
export -f get_container_status
export -f is_container_running 