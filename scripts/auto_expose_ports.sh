#!/bin/bash

# Script to automatically check for existing containers and expose ports for GPT-RAG projects
# This script should be run after cloning a repository to ensure ports are properly exposed

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO] $*${NC}"; }
log_error() { echo -e "${RED}[ERROR] $*${NC}" >&2; }
log_success() { echo -e "${GREEN}[SUCCESS] $*${NC}"; }
log_warning() { echo -e "${YELLOW}[WARNING] $*${NC}"; }

# Function to check if Docker is available
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        return 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        return 1
    fi
    
    return 0
}

# Function to check if container exists
container_exists() {
    local name="$1"
    docker ps -a --format '{{.Names}}' | grep -q "^${name}$"
}

# Function to check if container is running
container_running() {
    local name="$1"
    docker ps --format '{{.Names}}' | grep -q "^${name}$"
}

# Function to check if ports are already exposed
ports_exposed() {
    local container_name="$1"
    local ports_exposed=$(docker inspect --format='{{range $p, $conf := .HostConfig.PortBindings}}{{$p}} {{end}}' "$container_name")
    
    if [[ "$ports_exposed" == *"8000"* ]] && [[ "$ports_exposed" == *"3000"* ]]; then
        return 0 # Ports are exposed
    else
        return 1 # Ports are not exposed
    fi
}

# Function to detect GPT-RAG frontend project in a container
detect_gpt_rag_frontend_in_container() {
    local container_name="$1"
    
    # Check if the container has a frontend and backend directory
    if docker exec "$container_name" test -d "/app/frontend" && docker exec "$container_name" test -d "/app/backend"; then
        # Check for package.json in frontend directory
        if docker exec "$container_name" test -f "/app/frontend/package.json"; then
            # Check if it's a Vite or React project
            if docker exec "$container_name" grep -q "\"vite\"" "/app/frontend/package.json" || \
               docker exec "$container_name" grep -q "\"react\"" "/app/frontend/package.json"; then
                return 0 # It's a GPT-RAG frontend project
            fi
        fi
    fi
    
    return 1 # Not a GPT-RAG frontend project
}

# Function to expose ports for a container
expose_ports() {
    local container_name="$1"
    
    # Check if container exists
    if ! container_exists "$container_name"; then
        log_error "Container $container_name does not exist"
        return 1
    fi
    
    # Check if ports are already exposed
    if ports_exposed "$container_name"; then
        log_success "Ports are already exposed for container $container_name"
        return 0
    fi
    
    # Check if it's a GPT-RAG frontend project
    if ! detect_gpt_rag_frontend_in_container "$container_name"; then
        log_info "Container $container_name is not a GPT-RAG frontend project, skipping port exposure"
        return 0
    fi
    
    log_info "Detected GPT-RAG frontend project in container $container_name"
    
    # Get container info
    log_info "Getting container information..."
    local image=$(docker inspect --format='{{.Config.Image}}' "$container_name")
    local cmd=$(docker inspect --format='{{.Config.Cmd}}' "$container_name")
    local entrypoint=$(docker inspect --format='{{.Config.Entrypoint}}' "$container_name")
    local workdir=$(docker inspect --format='{{.Config.WorkingDir}}' "$container_name")
    local env=$(docker inspect --format='{{range .Config.Env}}--env {{.}} {{end}}' "$container_name")
    local volumes=$(docker inspect --format='{{range .HostConfig.Binds}}--volume {{.}} {{end}}' "$container_name")
    
    # Stop and remove the container
    if container_running "$container_name"; then
        log_info "Stopping container $container_name..."
        docker stop "$container_name"
    fi
    
    log_info "Removing container $container_name..."
    docker rm "$container_name"
    
    # Recreate the container with port mappings
    log_info "Recreating container with port mappings..."
    
    # Build the docker run command
    local run_cmd="docker run -d --name $container_name"
    
    # Try different port combinations if some ports are in use
    if ! docker run --rm -p 8000:8000 -p 3000:3000 -p 5000:5000 alpine:latest true &>/dev/null; then
        if ! docker run --rm -p 8000:8000 -p 3000:3000 -p 5001:5000 alpine:latest true &>/dev/null; then
            if ! docker run --rm -p 8000:8000 -p 3001:3000 -p 5001:5000 alpine:latest true &>/dev/null; then
                if ! docker run --rm -p 8001:8000 -p 3001:3000 -p 5001:5000 alpine:latest true &>/dev/null; then
                    log_warning "Could not find available port combination, using default ports which may fail"
                    run_cmd+=" -p 8000:8000 -p 3000:3000 -p 5000:5000"
                else
                    log_info "Using ports 8001:8000, 3001:3000, 5001:5000"
                    run_cmd+=" -p 8001:8000 -p 3001:3000 -p 5001:5000"
                fi
            else
                log_info "Using ports 8000:8000, 3001:3000, 5001:5000"
                run_cmd+=" -p 8000:8000 -p 3001:3000 -p 5001:5000"
            fi
        else
            log_info "Using ports 8000:8000, 3000:3000, 5001:5000"
            run_cmd+=" -p 8000:8000 -p 3000:3000 -p 5001:5000"
        fi
    else
        log_info "Using ports 8000:8000, 3000:3000, 5000:5000"
        run_cmd+=" -p 8000:8000 -p 3000:3000 -p 5000:5000"
    fi
    
    # Add environment variables
    run_cmd+=" $env"
    
    # Add volumes
    run_cmd+=" $volumes"
    
    # Add workdir if specified
    if [ -n "$workdir" ]; then
        run_cmd+=" --workdir $workdir"
    fi
    
    # Add entrypoint if specified
    if [ -n "$entrypoint" ] && [ "$entrypoint" != "[]" ]; then
        # Remove brackets and format for docker run
        entrypoint=$(echo "$entrypoint" | sed 's/\[//g' | sed 's/\]//g' | sed 's/,/ /g')
        run_cmd+=" --entrypoint $entrypoint"
    fi
    
    # Add image
    run_cmd+=" $image"
    
    # Add command if specified
    if [ -n "$cmd" ] && [ "$cmd" != "[]" ]; then
        # Remove brackets and format for docker run
        cmd=$(echo "$cmd" | sed 's/\[//g' | sed 's/\]//g' | sed 's/,/ /g')
        run_cmd+=" $cmd"
    fi
    
    # Execute the command
    log_info "Running: $run_cmd"
    eval "$run_cmd"
    
    if [ $? -eq 0 ]; then
        log_success "Container $container_name recreated with ports exposed"
        log_info "You can now access:"
        log_info "- Backend API: http://localhost:8000"
        log_info "- Frontend (if running on port 3000): http://localhost:3000"
        log_info "- Additional services (if running on port 5000): http://localhost:5000"
    else
        log_error "Failed to recreate container $container_name"
        return 1
    fi
    
    return 0
}

# Function to check all containers
check_all_containers() {
    log_info "Checking all containers for GPT-RAG frontend projects..."
    
    # Get all containers
    local containers=$(docker ps -a --format '{{.Names}}')
    
    # Check each container
    for container in $containers; do
        log_info "Checking container: $container"
        expose_ports "$container"
    done
}

# Main function
main() {
    log_info "=== Automatic Port Exposure for GPT-RAG Containers ==="
    
    # Check if Docker is available
    if ! check_docker; then
        log_error "Docker is required to run this script"
        exit 1
    fi
    
    # Check if a container name was provided
    if [ $# -ge 1 ]; then
        # Expose ports for the specified container
        expose_ports "$1"
    else
        # Check all containers
        check_all_containers
    fi
}

# Run main function with all arguments
main "$@" 