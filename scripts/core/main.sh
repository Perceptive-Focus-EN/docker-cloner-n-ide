#!/bin/bash

###########################################
# Main Orchestration Script
# This script serves as the central hub that coordinates all other components
###########################################

# Define script locations relative to this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Import order is important - dependencies must be loaded before dependents
# 1. Core utilities first
source "$SCRIPT_DIR/../utils/env_checker.sh"      # Environment checks
source "$SCRIPT_DIR/../utils/dependency_manager.sh" # Dependency management
source "$SCRIPT_DIR/../docker_helper.sh"          # Docker management

# 2. Docker-specific utilities
source "$SCRIPT_DIR/../docker/utils/permissions_handler.sh"  # Docker permissions
source "$SCRIPT_DIR/../docker/utils/container_manager.sh"    # Container operations

# 3. High-level handlers that depend on the above
source "$SCRIPT_DIR/../handlers/git_handler.sh"        # Git operations
source "$SCRIPT_DIR/../handlers/container_handler.sh"  # Container orchestration

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to handle cleanup on error
cleanup_on_error() {
    local error_msg="$1"
    local temp_dir="$2"
    local container_name="$3"
    
    echo -e "${RED}❌ Error: $error_msg${NC}"
    
    # Cleanup temporary directory if it exists
    if [ -d "$temp_dir" ]; then
        rm -rf "$temp_dir"
    fi
    
    # Remove container if it exists and was just created
    if [ -n "$container_name" ] && container_exists "$container_name"; then
        docker rm -f "$container_name" >/dev/null 2>&1
    fi
    
    return 1
}

# Function to handle repository cloning and container setup
handle_repository() {
    local repo_url="$1"
    local container_name="$2"
    local temp_dir
    
    # Create temporary directory
    temp_dir=$(mktemp -d)
    trap 'cleanup_on_error "Operation interrupted" "$temp_dir" "$container_name"' INT TERM
    
    # Clone repository
    if ! git clone "$repo_url" "$temp_dir"; then
        cleanup_on_error "Failed to clone repository" "$temp_dir" "$container_name"
        return 1
    fi
    echo -e "${GREEN}✅ Repository cloned successfully${NC}"
    
    # Detect repository type and verify dependencies
    local repo_type
    repo_type=$(detect_project_type "$temp_dir")
    if [ "$repo_type" = "unknown" ]; then
        cleanup_on_error "Could not detect project type" "$temp_dir" "$container_name"
        return 1
    fi
    
    echo -e "${GREEN}✅ Detected project type: $repo_type${NC}"
    
    # Check disk space before container operations
    if ! check_docker_space; then
        cleanup_on_error "Insufficient disk space" "$temp_dir" "$container_name"
        return 1
    fi
    
    # Create container with appropriate base image
    if ! create_container "$repo_type" "$container_name"; then
        cleanup_on_error "Failed to create container" "$temp_dir" "$container_name"
        return 1
    fi
    
    # Copy files to container
    if ! copy_to_container "$temp_dir" "$container_name" "/app"; then
        cleanup_on_error "Failed to copy files to container" "$temp_dir" "$container_name"
        return 1
    fi
    
    # Setup container environment
    if ! setup_container_env "$container_name" "$repo_type"; then
        cleanup_on_error "Failed to setup container environment" "$temp_dir" "$container_name"
        return 1
    fi
    
    # Cleanup temporary directory
    rm -rf "$temp_dir"
    
    echo -e "${GREEN}✅ Repository setup completed successfully!${NC}"
    return 0
}

# Function to show menu
show_menu() {
    clear
    echo -e "${YELLOW}=== GitHub Repository to Container Manager ===${NC}"
    echo "1. Clone from default repositories"
    echo "2. Clone from custom GitHub URL"
    echo "3. Upload and extract ZIP file"
    echo "4. Use existing cloned repository"
    echo "5. Exit"
    echo "==========================================="
}

# Function to handle menu selection
handle_menu() {
    while true; do
        show_menu
        read -p "Select an option (1-5): " choice
        
        case $choice in
            1)
                # Handle default repositories
                ;;
            2)
                echo -e "${YELLOW}📦 Clone from custom GitHub URL${NC}"
                read -p "Enter GitHub repository URL: " repo_url
                read -p "Enter container name (default: ${repo_url##*/}): " container_name
                container_name=${container_name:-${repo_url##*/}}
                
                # Check if container exists before proceeding
                if container_exists "$container_name"; then
                    result=$(handle_container_conflict "$container_name")
                    exit_code=$?
                    
                    if [ $exit_code -ne 0 ]; then
                        echo -e "${RED}Operation cancelled${NC}"
                        echo
                        read -p "Press Enter to continue..."
                        continue
                    fi
                    
                    # If a new name was generated, use it
                    if [ -n "$result" ]; then
                        container_name="$result"
                        echo -e "${GREEN}Using container name: ${container_name}${NC}"
                    fi
                fi
                
                # Handle repository
                handle_repository "$repo_url" "$container_name"
                ;;
            3)
                # Handle ZIP file upload
                echo -e "${YELLOW}Upload and Extract ZIP File${NC}"
                echo "Please drag and drop your ZIP file into this terminal window"
                echo "or enter the path manually:"
                read -p "ZIP file path: " zip_path
                
                if [ ! -f "$zip_path" ]; then
                    echo -e "${RED}File not found: $zip_path${NC}"
                    continue
                fi
                
                # Extract ZIP file
                temp_dir=$(mktemp -d)
                if ! unzip "$zip_path" -d "$temp_dir"; then
                    echo -e "${RED}Failed to extract ZIP file${NC}"
                    rm -rf "$temp_dir"
                    continue
                fi
                
                # Get the extracted directory name
                extracted_dir=$(basename "$zip_path" .zip)
                
                # Handle the extracted repository
                handle_repository "file://$temp_dir" "$extracted_dir"
                ;;
            4)
                # Handle existing repository
                echo -e "${YELLOW}Use Existing Cloned Repository${NC}"
                read -p "Enter repository directory path: " repo_path
                
                if [ ! -d "$repo_path" ]; then
                    echo -e "${RED}Directory not found: $repo_path${NC}"
                    continue
                fi
                
                # Get repository name for container
                repo_name=$(basename "$repo_path")
                
                # Handle the repository
                handle_repository "file://$repo_path" "$repo_name"
                ;;
            5)
                echo -e "${YELLOW}👋 Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Invalid option${NC}"
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
}

# Main function
main() {
    # Check environment first
    if ! check_environment; then
        echo -e "${RED}❌ Environment check failed${NC}"
        exit 1
    fi
    
    # Check Docker status
    if ! manage_docker; then
        echo -e "${RED}❌ Docker setup failed${NC}"
        exit 1
    fi
    
    # Show menu and handle selection
    handle_menu
}

# Run main function
main 