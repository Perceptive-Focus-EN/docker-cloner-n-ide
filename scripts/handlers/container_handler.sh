#!/bin/bash

###########################################
# Container Handler Script
# High-level container orchestration that depends on:
# - docker/utils/permissions_handler.sh
# - docker/utils/container_manager.sh
#
# Workflow:
# 1. Container Creation
#    ├── Check Docker daemon
#    ├── Handle name conflicts (container_manager.sh)
#    └── Create container with appropriate image
#
# 2. File Operations
#    ├── Check/fix permissions (permissions_handler.sh)
#    ├── Copy files to container
#    └── Verify permissions after copy
#
# 3. Environment Setup
#    ├── Install basic tools
#    ├── Configure project-specific environment
#    └── Verify setup success
###########################################

# Import Docker utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Required utilities
source "$SCRIPT_DIR/../docker/utils/permissions_handler.sh"  # For permission fixes
source "$SCRIPT_DIR/../docker/utils/container_manager.sh"    # For container operations

# Required functions from permissions_handler.sh
required_permission_functions=(
    "fix_docker_permissions"
    "check_and_fix_permissions"
)

# Required functions from container_manager.sh
required_container_functions=(
    "list_containers"
    "remove_container"
    "rename_container"
    "handle_container_conflict"
    "container_exists"
    "get_container_status"
    "is_container_running"
)

# Verify all required functions
for func in "${required_permission_functions[@]}" "${required_container_functions[@]}"; do
    if ! command -v "$func" >/dev/null 2>&1; then
        echo "❌ Required function not found: $func"
        exit 1
    fi
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if Docker daemon is running
check_docker_daemon() {
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker daemon is not running${NC}"
        echo -e "${YELLOW}💡 Please start Docker Desktop and try again${NC}"
        return 1
    fi
    return 0
}

# Function to generate unique container name
generate_unique_container_name() {
    local base_name="$1"
    local counter=1
    local name="$base_name"
    
    while docker ps -a --format '{{.Names}}' | grep -q "^${name}$"; do
        name="${base_name}_${counter}"
        ((counter++))
    done
    
    echo "$name"
}

# Function to check Docker disk space
check_docker_space() {
    # Get disk usage percentage for Docker root dir
    local usage
    usage=$(docker system df --format '{{.TotalPercentage}}' 2>/dev/null | head -n 1 | tr -d '%')
    
    # If usage is over 85%, suggest cleanup
    if [ "${usage:-0}" -gt 85 ]; then
        echo -e "\n${YELLOW}⚠️  Docker disk usage is high (${usage}%)${NC}"
        echo -e "${YELLOW}Would you like to run the cleanup utility?${NC}"
        read -p "Run cleanup? (y/N): " should_cleanup
        
        if [[ "$should_cleanup" =~ ^[Yy]$ ]]; then
            # Source and run the cleanup script
            source "$SCRIPT_DIR/../docker/utils/docker_cleanup.sh"
            cleanup_docker
            return $?
        fi
    fi
    return 0
}

# Function to create container based on project type
create_container() {
    local project_type="$1"
    local container_name="$2"
    
    # Check Docker daemon first
    check_docker_daemon || return 1
    
    # Check disk space and offer cleanup if needed
    check_docker_space
    
    echo -e "${YELLOW}🐳 Creating container for ${project_type} project...${NC}"
    
    # Check if container exists and handle conflict
    if container_exists "$container_name"; then
        local result
        if ! result=$(handle_container_conflict "$container_name"); then
            return 1
        fi
        # If a new name was generated, use it
        if [ "$result" != "" ]; then
            container_name="$result"
        fi
    fi
    
    # Select base image based on project type
    local base_image
    case "$project_type" in
        "python"|"django"|"flask"|"fastapi"|"data-science"|"ml-ai")
            base_image="python:3.9-slim"
            ;;
        "nodejs"|"react"|"react-typescript"|"nextjs"|"typescript"|"azure-react")
            base_image="node:20-slim"
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
            base_image="ubuntu:latest"
            ;;
    esac
    
    # Pull the image first
    echo -e "${YELLOW}📥 Pulling base image ${base_image}...${NC}"
    if ! docker pull "$base_image" >/dev/null; then
        echo -e "${RED}❌ Failed to pull base image${NC}"
        return 1
    fi
    
    # Create container
    echo -e "${YELLOW}🚀 Creating new container...${NC}"
    if docker run -d --name "$container_name" -v /tmp/repo:/app "$base_image" sleep infinity; then
        echo -e "${GREEN}✅ Container created successfully${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to create container${NC}"
        return 1
    fi
}

# Function to setup container environment
setup_container_env() {
    local container_name="$1"
    local project_type="$2"
    
    # Check Docker daemon first
    check_docker_daemon || return 1
    
    echo -e "${YELLOW}🔧 Setting up container environment...${NC}"
    
    # Install basic tools - git and curl are useful in all environments
    docker exec "$container_name" bash -c "apt-get update && apt-get install -y git curl" || {
        echo -e "${RED}❌ Failed to install basic tools${NC}"
        return 1
    }
    
    # Setup based on project type
    case "$project_type" in
        "nodejs"|"react"|"react-typescript"|"nextjs"|"typescript"|"azure-react")
            # Node.js-specific setup - node and npm are already installed in node images
            docker exec "$container_name" bash -c "
                cd /app && \
                
                # Check for monorepo structure with frontend/backend
                if [ -d 'frontend' ] && [ -f 'frontend/package.json' ]; then
                    echo '📦 Setting up frontend...' && \
                    cd frontend && npm install
                    
                    # Check if this is a Vite project
                    if [ -f 'vite.config.ts' ] || [ -f 'vite.config.js' ]; then
                        echo '🛠️ Detected Vite project, setting up development environment...'
                        # Install Vite globally for convenience
                        npm install -g vite
                    fi
                    
                    # Check if we need to build the project
                    if grep -q '\"build\"' package.json; then
                        echo '🏗️ Building frontend project...'
                        npm run build
                    fi
                elif [ -f 'package.json' ]; then
                    echo '📦 Installing dependencies...' && \
                    npm install
                    
                    # Check if this is a Vite project
                    if [ -f 'vite.config.ts' ] || [ -f 'vite.config.js' ]; then
                        echo '🛠️ Detected Vite project, setting up development environment...'
                        # Install Vite globally for convenience
                        npm install -g vite
                    fi
                    
                    # Check if we need to build the project
                    if grep -q '\"build\"' package.json; then
                        echo '🏗️ Building project...'
                        npm run build
                    fi
                fi
                
                # Check for backend in monorepo structure
                if [ -d '/app/backend' ]; then
                    echo '📦 Setting up backend...' && \
                    cd /app/backend
                    
                    # Check for Python backend
                    if [ -f 'requirements.txt' ]; then
                        echo '🐍 Python backend detected, setting up environment...' && \
                        apt-get update && \
                        apt-get install -y python3-venv python3-pip && \
                        python3 -m venv venv && \
                        . venv/bin/activate && \
                        pip install -r requirements.txt
                        
                        # Create activation script for convenience
                        echo '#!/bin/bash' > activate.sh && \
                        echo 'source venv/bin/activate' >> activate.sh && \
                        chmod +x activate.sh
                    # Check for Node.js backend
                    elif [ -f 'package.json' ]; then
                        echo '📦 Node.js backend detected, installing dependencies...' && \
                        npm install
                    fi
                fi
                
                # Create convenience scripts for monorepo
                if [ -d '/app/frontend' ] && [ -d '/app/backend' ]; then
                    echo '📝 Creating convenience scripts...'
                    
                    # Frontend start script
                    echo '#!/bin/bash' > /app/start_frontend.sh && \
                    echo 'cd /app/frontend && npm start' >> /app/start_frontend.sh && \
                    chmod +x /app/start_frontend.sh
                    
                    # Backend start script - handle both Python and Node.js
                    echo '#!/bin/bash' > /app/start_backend.sh && \
                    if [ -f '/app/backend/requirements.txt' ]; then
                        echo 'cd /app/backend && source venv/bin/activate && python app.py' >> /app/start_backend.sh
                    elif [ -f '/app/backend/package.json' ]; then
                        echo 'cd /app/backend && npm start' >> /app/start_backend.sh
                    fi
                    chmod +x /app/start_backend.sh
                fi
                
                echo '✅ Node.js/React environment setup complete!'
            " || {
                echo -e "${RED}❌ Failed to setup Node.js/React environment${NC}"
                return 1
            }
            ;;
        "python"|"django"|"flask"|"fastapi"|"data-science"|"ml-ai")
            # Python-specific setup - pip is already installed in python images
            docker exec "$container_name" bash -c "
                cd /app && \
                apt-get update && \
                apt-get install -y python3-venv python3-pip && \
                python3 -m venv /app/venv && \
                . /app/venv/bin/activate && \
                
                # Check for different dependency files and install them
                if [ -f 'requirements.txt' ]; then
                    echo '📦 Installing dependencies from requirements.txt...' && \
                    pip install -r requirements.txt
                elif [ -f 'pyproject.toml' ]; then
                    echo '📦 Installing project with pip...' && \
                    pip install -e .
                elif [ -f 'setup.py' ]; then
                    echo '📦 Installing project with pip...' && \
                    pip install -e .
                fi && \
                
                # Check for specific Python project types and install additional tools
                if [ '$project_type' = 'django' ] || grep -q 'django' requirements.txt 2>/dev/null || grep -q 'django' pyproject.toml 2>/dev/null || [ -f 'manage.py' ]; then
                    echo '🌐 Django project detected, installing development tools...' && \
                    pip install django-debug-toolbar
                elif [ '$project_type' = 'flask' ] || grep -q 'flask' requirements.txt 2>/dev/null || grep -q 'flask' pyproject.toml 2>/dev/null; then
                    echo '🌐 Flask project detected, installing development tools...' && \
                    pip install flask-debugtoolbar
                elif [ '$project_type' = 'fastapi' ] || grep -q 'fastapi' requirements.txt 2>/dev/null || grep -q 'fastapi' pyproject.toml 2>/dev/null; then
                    echo '🌐 FastAPI project detected, installing development tools...' && \
                    pip install fastapi-debug-toolbar
                elif [ '$project_type' = 'data-science' ] || grep -q 'pandas\|numpy\|matplotlib' requirements.txt 2>/dev/null || grep -q 'pandas\|numpy\|matplotlib' pyproject.toml 2>/dev/null; then
                    echo '📊 Data Science project detected, installing additional tools...' && \
                    pip install jupyterlab
                elif [ '$project_type' = 'ml-ai' ] || grep -q 'tensorflow\|torch\|sklearn' requirements.txt 2>/dev/null || grep -q 'tensorflow\|torch\|sklearn' pyproject.toml 2>/dev/null; then
                    echo '🧠 ML/AI project detected, installing additional tools...' && \
                    pip install jupyterlab tensorboard
                fi && \
                
                # Create activation script for convenience
                echo '#!/bin/bash' > /app/activate.sh && \
                echo 'source /app/venv/bin/activate' >> /app/activate.sh && \
                chmod +x /app/activate.sh && \
                
                echo '✅ Python environment setup complete!'
            " || {
                echo -e "${RED}❌ Failed to setup Python environment${NC}"
                return 1
            }
            ;;
        "java"|"spring-boot")
            # Java-specific setup - Java is already installed in openjdk images
            docker exec "$container_name" bash -c "
                apt-get install -y maven && \
                cd /app && \
                if [ -f pom.xml ]; then
                    mvn install
                fi
            "
            ;;
        "cpp")
            # C++ setup - gcc and basic build tools are already installed in gcc images
            docker exec "$container_name" bash -c "
                apt-get install -y cmake && \
                cd /app && \
                if [ -f CMakeLists.txt ]; then
                    mkdir -p build && cd build && \
                    cmake .. && make
                elif [ -f Makefile ]; then
                    make
                fi
            "
            ;;
        "rust")
            # Rust setup - rust is already installed in rust images
            docker exec "$container_name" bash -c "
                cd /app && \
                if [ -f Cargo.toml ]; then
                    cargo build
                fi
            "
            ;;
        "golang"|"go")
            # Go setup - go is already installed in golang images
            docker exec "$container_name" bash -c "
                cd /app && \
                if [ -f go.mod ]; then
                    go build
                fi
            "
            ;;
        *)
            # For unknown project types, try to detect common patterns
            docker exec "$container_name" bash -c "
                # Check for monorepo structure
                if [ -d '/app/frontend' ] && [ -d '/app/backend' ]; then
                    echo '📦 Detected monorepo structure, setting up environment...'
                    
                    # Setup frontend
                    if [ -f '/app/frontend/package.json' ]; then
                        echo '📦 Setting up frontend...'
                        apt-get update && \
                        apt-get install -y nodejs npm && \
                        cd /app/frontend && npm install
                    fi
                    
                    # Setup backend
                    if [ -f '/app/backend/requirements.txt' ]; then
                        echo '📦 Setting up Python backend...'
                        apt-get install -y python3-venv python3-pip && \
                        cd /app/backend && \
                        python3 -m venv venv && \
                        . venv/bin/activate && \
                        pip install -r requirements.txt
                    elif [ -f '/app/backend/package.json' ]; then
                        echo '📦 Setting up Node.js backend...'
                        cd /app/backend && npm install
                    fi
                # Check for package.json (Node.js)
                elif [ -f '/app/package.json' ]; then
                    apt-get update && \
                    apt-get install -y nodejs npm && \
                    cd /app && npm install
                # Check for requirements.txt (Python)
                elif [ -f '/app/requirements.txt' ]; then
                    apt-get install -y python3-pip && \
                    cd /app && pip install -r requirements.txt
                fi
            "
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Container environment setup complete${NC}"
        echo
        echo -e "${YELLOW}=== Next Steps ===${NC}"
        echo -e "1. ${GREEN}Access container:${NC} docker exec -it $container_name bash"
        echo -e "2. ${GREEN}View logs:${NC} docker logs $container_name"
        echo -e "3. ${GREEN}Stop container:${NC} docker stop $container_name"
        echo -e "4. ${GREEN}Start container:${NC} docker start $container_name"
        echo
        echo -e "${YELLOW}Your project is ready in:${NC} /app"
        echo -e "${YELLOW}Container name:${NC} $container_name"
        return 0
    else
        echo -e "${RED}❌ Failed to setup container environment${NC}"
        return 1
    fi
}

# Function to copy files to container
copy_to_container() {
    local source_path="$1"
    local container_name="$2"
    local target_path="$3"
    
    # Check Docker daemon first
    check_docker_daemon || return 1
    
    echo -e "${YELLOW}📂 Copying files to container...${NC}"
    
    # Fix permissions before copying
    check_and_fix_permissions "$container_name" "$target_path" || return 1
    
    # Copy files excluding .git directory
    if tar -C "$source_path" --exclude='.git' -czf - . | docker cp - "$container_name:$target_path"; then
        echo -e "${GREEN}✅ Files copied successfully${NC}"
        # Fix permissions after copy
        check_and_fix_permissions "$container_name" "$target_path" || return 1
        return 0
    else
        echo -e "${RED}❌ Failed to copy files${NC}"
        return 1
    fi
}

# Function to handle container operations
handle_container() {
    local project_type="$1"
    local container_name="$2"
    local source_path="$3"
    
    # Check disk space before any operations
    check_docker_space
    
    # Create container
    create_container "$project_type" "$container_name" || return 1
    
    # Copy files to container
    copy_to_container "$source_path" "$container_name" "/app" || return 1
    
    # Setup container environment
    setup_container_env "$container_name" "$project_type" || return 1
    
    return 0
}

# Export functions
export -f check_docker_daemon
export -f generate_unique_container_name
export -f create_container
export -f setup_container_env
export -f copy_to_container
export -f handle_container
export -f check_docker_space 