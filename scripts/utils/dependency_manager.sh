#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to detect project type
detect_project_type() {
    local project_dir="$1"
    local project_type=""
    
    echo -e "${YELLOW}🔍 Detecting project type...${NC}"
    
    # Check if our advanced project detector exists
    if [ -f "$SCRIPT_DIR/project_detector.sh" ]; then
        echo -e "${GREEN}✅ Using advanced project detection${NC}"
        # Source the project detector script
        source "$SCRIPT_DIR/project_detector.sh"
        # Run the project detector and capture the output
        project_type=$(analyze_repository "$project_dir")
    else
        echo -e "${YELLOW}⚠️ Advanced project detector not found, using basic detection${NC}"
        # Basic detection logic (fallback)
        if [ -d "$project_dir/frontend" ] && [ -d "$project_dir/backend" ]; then
            # Check for GPT-RAG project structure
            project_type="gpt-rag"
        elif [ -f "$project_dir/package.json" ]; then
            # Check for React/Node.js project
            if grep -q "react" "$project_dir/package.json"; then
                if grep -q "typescript" "$project_dir/package.json"; then
                    project_type="react-typescript"
                else
                    project_type="react"
                fi
            elif grep -q "next" "$project_dir/package.json"; then
                project_type="nextjs"
            else
                project_type="nodejs"
            fi
        elif [ -f "$project_dir/requirements.txt" ] || [ -f "$project_dir/setup.py" ] || [ -f "$project_dir/pyproject.toml" ]; then
            # Check for Python project
            project_type="python"
        elif [ -f "$project_dir/pom.xml" ] || [ -f "$project_dir/build.gradle" ]; then
            # Check for Java project
            project_type="java"
        elif [ -f "$project_dir/CMakeLists.txt" ] || find "$project_dir" -name "*.cpp" | grep -q .; then
            # Check for C++ project
            project_type="cpp"
        elif [ -f "$project_dir/Cargo.toml" ]; then
            # Check for Rust project
            project_type="rust"
        elif [ -f "$project_dir/go.mod" ]; then
            # Check for Go project
            project_type="golang"
        else
            # Default to unknown
            project_type="unknown"
        fi
    fi
    
    if [ -z "$project_type" ] || [ "$project_type" = "unknown" ]; then
        echo -e "${RED}❌ Could not determine project type${NC}"
        echo -e "${YELLOW}Supported project types:${NC}"
        echo -e "  - python (Django, Flask, FastAPI, Data Science, ML/AI)"
        echo -e "  - nodejs, react, react-typescript, nextjs"
        echo -e "  - java, cpp, rust, golang"
        echo -e "  - gpt-rag (GPT Retrieval Augmented Generation)"
        return 1
    else
        echo -e "${GREEN}✅ Detected project type: ${YELLOW}$project_type${NC}"
        echo "$project_type"
        return 0
    fi
}

# Function to install dependencies based on project type
install_dependencies() {
    local project_type="$1"
    local project_dir="$2"
    
    echo -e "${YELLOW}Installing dependencies for $project_type project...${NC}"
    
    case "$project_type" in
        "azure-react")
            # Install Node.js and npm
            apt-get update && apt-get install -y nodejs npm
            
            # Install global dependencies
            npm install -g typescript ts-node @azure/static-web-apps-cli @microsoft/rush
            
            # Install frontend dependencies
            if [ -f "$project_dir/frontend/package.json" ]; then
                cd "$project_dir/frontend" && npm install
                
                # Build frontend
                if grep -q "\"build\":" "package.json"; then
                    npm run build
                fi
            fi
            
            # Install backend dependencies if they exist
            if [ -f "$project_dir/backend/requirements.txt" ]; then
                apt-get update && apt-get install -y python3 python3-pip
                cd "$project_dir/backend" && pip3 install -r requirements.txt
            fi
            ;;
            
        "react-typescript"|"nextjs"|"typescript"|"react")
            # Install Node.js, npm and TypeScript
            apt-get update && apt-get install -y nodejs npm
            npm install -g typescript ts-node
            
            # Install project dependencies
            if [ -f "$project_dir/package.json" ]; then
                cd "$project_dir" && npm install
                
                # Build project if build script exists
                if grep -q "\"build\":" "package.json"; then
                    npm run build
                elif [ "$project_type" = "typescript" ]; then
                    tsc
                fi
            fi
            ;;
            
        "nodejs"|"frontend")
            # Install Node.js and npm
            apt-get update && apt-get install -y nodejs npm
            # Install project dependencies
            if [ -f "$project_dir/package.json" ]; then
                cd "$project_dir" && npm install
                
                # Build project if build script exists
                if grep -q "\"build\":" "package.json"; then
                    npm run build
                fi
            fi
            ;;
            
        "python")
            # Install Python and pip
            apt-get update && apt-get install -y python3 python3-pip
            # Install project dependencies
            if [ -f "$project_dir/requirements.txt" ]; then
                pip3 install -r "$project_dir/requirements.txt"
            fi
            ;;
            
        "java")
            # Install Java and Maven
            apt-get update && apt-get install -y openjdk-11-jdk maven
            ;;
            
        "cpp")
            # Install C++ build tools
            apt-get update && apt-get install -y build-essential cmake
            ;;
            
        "rust")
            # Install Rust
            apt-get update && apt-get install -y curl
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            source $HOME/.cargo/env
            ;;
            
        "golang")
            # Install Go
            apt-get update && apt-get install -y golang-go
            ;;
            
        *)
            echo -e "${RED}Unknown project type: $project_type${NC}"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}Dependencies installed successfully!${NC}"
    return 0
}

# Function to verify installation
verify_installation() {
    local project_type="$1"
    
    echo -e "${YELLOW}Verifying installation...${NC}"
    
    case "$project_type" in
        "azure-react")
            if ! command -v node &> /dev/null; then
                echo -e "${RED}node not found${NC}"
                return 1
            fi
            if ! command -v tsc &> /dev/null; then
                echo -e "${RED}typescript compiler not found${NC}"
                return 1
            fi
            if ! command -v swa &> /dev/null; then
                echo -e "${RED}static web apps cli not found${NC}"
                return 1
            fi
            ;;
            
        "nextjs")
            if ! command -v next &> /dev/null; then
                echo -e "${RED}next not found${NC}"
                return 1
            fi
            if ! command -v node &> /dev/null; then
                echo -e "${RED}node not found${NC}"
                return 1
            fi
            ;;
            
        "typescript")
            if ! command -v tsc &> /dev/null; then
                echo -e "${RED}typescript compiler not found${NC}"
                return 1
            fi
            if ! command -v node &> /dev/null; then
                echo -e "${RED}node not found${NC}"
                return 1
            fi
            ;;
            
        "nodejs"|"frontend")
            if ! command -v node &> /dev/null; then
                echo -e "${RED}node not found${NC}"
                return 1
            fi
            ;;
            
        "python")
            if ! command -v python3 &> /dev/null; then
                echo -e "${RED}python3 not found${NC}"
                return 1
            fi
            ;;
            
        "java")
            if ! command -v java &> /dev/null; then
                echo -e "${RED}java not found${NC}"
                return 1
            fi
            ;;
            
        "cpp")
            if ! command -v g++ &> /dev/null; then
                echo -e "${RED}g++ not found${NC}"
                return 1
            fi
            ;;
            
        "rust")
            if ! command -v rustc &> /dev/null; then
                echo -e "${RED}rustc not found${NC}"
                return 1
            fi
            ;;
            
        "golang")
            if ! command -v go &> /dev/null; then
                echo -e "${RED}go not found${NC}"
                return 1
            fi
            ;;
    esac
    
    echo -e "${GREEN}Installation verified successfully!${NC}"
    return 0
}

# Function to upload and unzip files to container
upload_and_unzip() {
    local zip_file="$1"
    local container_name="${2:-loinc-demo-app}"
    local target_dir="${3:-/app}"  # Default to /app directory
    
    echo -e "${YELLOW}📦 Processing zip file...${NC}"
    
    # Validate inputs
    if [ -z "$zip_file" ]; then
        echo -e "${RED}❌ Please provide a zip file to process${NC}"
        return 1
    fi
    
    if [ ! -f "$zip_file" ]; then
        echo -e "${RED}❌ Cannot find zip file: $zip_file${NC}"
        return 1
    fi
    
    # Create a temporary workspace
    local temp_dir=$(mktemp -d)
    echo -e "${YELLOW}🔨 Creating workspace...${NC}"
    
    # Copy zip to temp directory
    cp "$zip_file" "$temp_dir/"
    local zip_name=$(basename "$zip_file")
    
    # Check if container exists and is running
    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        echo -e "${YELLOW}🚀 Container not running, attempting to start it...${NC}"
        docker start "$container_name" || {
            echo -e "${RED}❌ Failed to start container${NC}"
            rm -rf "$temp_dir"
            return 1
        }
    fi
    
    echo -e "${YELLOW}📤 Transferring to container...${NC}"
    # Stream the zip file directly into the container and unzip in one motion
    cat "$temp_dir/$zip_name" | docker exec -i "$container_name" sh -c "cat > /tmp/$zip_name && cd $target_dir && unzip -o /tmp/$zip_name && rm /tmp/$zip_name"
    
    local status=$?
    if [ $status -eq 0 ]; then
        echo -e "${GREEN}✅ Files extracted successfully to $target_dir${NC}"
    else
        echo -e "${RED}❌ Extraction failed${NC}"
    fi
    
    # Clean up
    echo -e "${YELLOW}🧹 Cleaning up...${NC}"
    rm -rf "$temp_dir"
    
    return $status
}

# Function to handle container operations
handle_container() {
    local operation="$1"
    local zip_file="$2"
    local container_name="${3:-loinc-demo-app}"
    local target_dir="${4:-/app}"
    
    case "$operation" in
        "upload")
            if [ -z "$zip_file" ]; then
                echo -e "${RED}❌ Error: No zip file provided${NC}"
                echo -e "${YELLOW}Usage: handle_container upload <zip_file> [container_name] [target_dir]${NC}"
                return 1
            fi
            upload_and_unzip "$zip_file" "$container_name" "$target_dir"
            ;;
        "start")
            echo -e "${YELLOW}🚀 Starting container $container_name...${NC}"
            docker start "$container_name"
            ;;
        "stop")
            echo -e "${YELLOW}🛑 Stopping container $container_name...${NC}"
            docker stop "$container_name"
            ;;
        "restart")
            echo -e "${YELLOW}🔄 Restarting container $container_name...${NC}"
            docker restart "$container_name"
            ;;
        *)
            echo -e "${RED}❌ Unknown operation: $operation${NC}"
            echo -e "${YELLOW}Available operations:${NC}"
            echo "  - upload <zip_file> [container_name] [target_dir]"
            echo "  - start [container_name]"
            echo "  - stop [container_name]"
            echo "  - restart [container_name]"
            return 1
            ;;
    esac
}

# Add these functions after the existing code
setup_default_environments() {
    echo -e "${YELLOW}🔧 Setting up default environments...${NC}"
    
    # Python environments
    setup_python_environment
    
    # Node.js environment
    setup_node_environment
    
    # C++ environment
    setup_cpp_environment
}

setup_python_environment() {
    echo -e "${YELLOW}🐍 Setting up Python environment...${NC}"
    apt-get update && apt-get install -y python3 python3-pip python3-venv
    
    # Create default venv if it doesn't exist
    if [ ! -d "venv" ]; then
        python3 -m venv venv
    fi
    
    # Check for conda
    if command -v conda &> /dev/null; then
        echo -e "${GREEN}✅ Conda found${NC}"
        # Create default environments if they don't exist
        conda env list | grep -q "ml-gpu" || conda create -n ml-gpu python=3.9 -y
        conda env list | grep -q "ml-torch" || conda create -n ml-torch python=3.9 -y
        conda env list | grep -q "ml-rag" || conda create -n ml-rag python=3.9 -y
    fi
}

setup_node_environment() {
    echo -e "${YELLOW}📦 Setting up Node.js environment...${NC}"
    # Install Node.js and npm if not present
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt-get install -y nodejs
    fi
    
    # Install common global packages
    npm install -g typescript ts-node vite @vitejs/create-app create-next-app
}

setup_cpp_environment() {
    echo -e "${YELLOW}🔧 Setting up C++ environment...${NC}"
    apt-get update && apt-get install -y build-essential cmake make
}

activate_project_environment() {
    local project_dir="$1"
    echo -e "${YELLOW}🔍 Activating appropriate environment for project...${NC}"
    
    # Python project
    if [ -f "$project_dir/requirements.txt" ] || [ -f "$project_dir/pyproject.toml" ]; then
        if [ -d "$project_dir/venv" ]; then
            echo -e "${GREEN}✅ Found Python venv${NC}"
            source "$project_dir/venv/bin/activate"
        elif command -v conda &> /dev/null; then
            echo -e "${GREEN}✅ Using conda environment${NC}"
            if grep -q "torch" "$project_dir/requirements.txt" 2>/dev/null; then
                conda activate ml-torch
            elif grep -q "transformers" "$project_dir/requirements.txt" 2>/dev/null; then
                conda activate ml-rag
            else
                conda activate base
            fi
        fi
        pip install -r "$project_dir/requirements.txt"
    fi
    
    # Node.js project
    if [ -f "$project_dir/package.json" ]; then
        echo -e "${GREEN}✅ Installing Node.js dependencies${NC}"
        cd "$project_dir" && npm install
        
        # Check for build script
        if grep -q "\"build\":" "package.json"; then
            npm run build
        fi
    fi
    
    # C++ project
    if [ -f "$project_dir/CMakeLists.txt" ]; then
        echo -e "${GREEN}✅ Building C++ project${NC}"
        mkdir -p build && cd build && cmake .. && make
    elif [ -f "$project_dir/Makefile" ]; then
        make
    fi
}

# Add to the main workflow
detect_and_setup_environment() {
    local project_dir="$1"
    
    # First ensure base environments are available
    setup_default_environments
    
    # Then detect and activate project-specific environment
    activate_project_environment "$project_dir"
    
    # Finally, verify the setup
    verify_installation "$(detect_project_type "$project_dir")"
}

# Export functions
export -f detect_project_type
export -f install_dependencies
export -f verify_installation
export -f handle_container
export -f upload_and_unzip 