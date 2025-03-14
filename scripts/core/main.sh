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
source "$BASE_DIR/scripts/utils/env_checker.sh"      # Environment checks
source "$BASE_DIR/scripts/utils/dependency_manager.sh" # Dependency management
source "$BASE_DIR/scripts/docker_helper.sh"          # Docker management

# 2. Docker-specific utilities
source "$BASE_DIR/scripts/docker/utils/permissions_handler.sh"  # Docker permissions
source "$BASE_DIR/scripts/docker/utils/container_manager.sh"    # Container operations

# 3. High-level handlers that depend on the above
source "$BASE_DIR/scripts/handlers/git_handler.sh"        # Git operations
source "$BASE_DIR/scripts/handlers/container_handler.sh"  # Container orchestration

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
    
    # Check disk space before container operations
    if ! check_docker_space; then
        cleanup_on_error "Insufficient disk space" "$temp_dir" "$container_name"
        return 1
    fi
    
    # Create container with repository
    if ! create_container "$temp_dir" "$container_name"; then
        cleanup_on_error "Failed to create container" "$temp_dir" "$container_name"
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

# Function to validate container name
validate_container_name() {
    local container_name="$1"
    # Remove any special characters and spaces, keep only alphanumeric, dashes, and dots
    container_name=$(echo "$container_name" | sed 's/[^a-zA-Z0-9\._-]//g')
    echo "$container_name"
}

# Function to create container
create_container() {
    local repo_path="$1"
    local container_name="$2"
    
    # Validate container name
    container_name=$(validate_container_name "$container_name")
    
    # Detect project type using the project detector
    local project_type
    project_type=$(detect_project_type "$repo_path")
    echo -e "${GREEN}✅ Detected project type: $project_type${NC}"
    
    # Check for container conflict and handle it
    if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        echo -e "\n=== Container Conflict Resolution ==="
        echo -e "⚠️  Container $container_name already exists\n"
        
        # Show all containers in a single output
        echo "Current Docker Containers:"
        echo "------------------------"
        docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.ID}}" | cat
        
        echo -e "\nAvailable Options:"
        echo "----------------"
        echo "1. Remove existing container $container_name"
        echo "2. Rename existing container"
        echo "3. Auto-generate new unique name"
        echo "4. Cancel operation"
        
        read -p "What would you like to do? " action
        
        case "$action" in
            1)
                echo -e "\n🗑️  Removing container $container_name..."
                docker rm -f "$container_name" >/dev/null 2>&1
                if [ $? -eq 0 ]; then
                    echo "✅ Container removed successfully"
                else
                    echo "❌ Failed to remove container"
                    return 1
                fi
                ;;
            2)
                read -p "Enter new name for existing container: " new_name
                new_name=$(validate_container_name "$new_name")
                docker rename "$container_name" "$new_name" >/dev/null 2>&1
                if [ $? -eq 0 ]; then
                    echo "✅ Container renamed successfully"
                    container_name="$new_name"
                else
                    echo "❌ Failed to rename container"
                    return 1
                fi
                ;;
            3)
                local timestamp=$(date +%Y%m%d_%H%M%S)
                container_name="${container_name}_${timestamp}"
                echo "✅ New container name: $container_name"
                ;;
            4)
                echo "Operation cancelled"
                return 1
                ;;
            *)
                echo "Invalid option. Please try again."
                return 1
                ;;
        esac
    fi
    
    # Select base image based on project type
    local base_image
    case "$project_type" in
        "react"|"react-typescript"|"nextjs"|"typescript"|"nodejs"|"azure-react"|"frontend")
            # Use Node.js image for all JavaScript/TypeScript projects
            base_image="node:20-slim"
            ;;
        "python"|"django"|"flask"|"fastapi"|"data-science"|"ml-ai")
            base_image="python:3.9-slim"
            ;;
        "java"|"spring-boot")
            base_image="openjdk:17-slim"
            ;;
        "cpp")
            base_image="gcc:latest"
            ;;
        "rust")
            base_image="rust:slim"
            ;;
        "golang"|"go")
            base_image="golang:1.17-alpine"
            ;;
        *)
            # For unknown project types or monorepo structures, use Ubuntu
            # This gives us flexibility to install multiple runtimes
            base_image="ubuntu:latest"
            ;;
    esac
    
    echo "🐳 Creating container $container_name with $base_image image..."
    docker run -d --name "$container_name" "$base_image" tail -f /dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ Container created successfully"
        
        # Copy repository contents to container
        echo "📂 Copying repository contents to container..."
        docker cp "$repo_path/." "$container_name:/app/"
        
        if [ $? -eq 0 ]; then
            echo "✅ Repository contents copied successfully"
            
            # Setup container environment based on project type
            echo "🔧 Setting up container environment for $project_type project..."
            if setup_container_env "$container_name" "$project_type"; then
                echo "✅ Container environment setup complete"
                return 0
            else
                echo "❌ Failed to setup container environment"
                docker rm -f "$container_name" >/dev/null 2>&1
                return 1
            fi
        else
            echo "❌ Failed to copy repository contents"
            docker rm -f "$container_name" >/dev/null 2>&1
            return 1
        fi
    else
        echo "❌ Failed to create container"
        return 1
    fi
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