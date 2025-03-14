#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to detect project type
detect_project_type() {
    local project_dir="$1"
    
    # Check if our advanced project detector exists
    if [ -f "$SCRIPT_DIR/project_detector.sh" ]; then
        # Source the project detector script
        source "$SCRIPT_DIR/project_detector.sh"
        
        # Use the advanced analyzer
        local project_type=$(analyze_repository "$project_dir")
        echo "$project_type"
        return 0
    else
        # Fall back to the basic detection logic
        echo -e "${YELLOW}🔍 Detecting project type in: $project_dir${NC}"
        
        # First check if directory exists
        if [ ! -d "$project_dir" ]; then
            echo -e "${RED}❌ Project directory not found: $project_dir${NC}"
            echo "unknown"
            return 1
        fi
        
        # Debug output
        echo -e "${YELLOW}📂 Directory contents:${NC}"
        ls -la "$project_dir"
        
        # Check for GPT-RAG or similar project structure
        if [ -d "$project_dir/frontend" ] && [ -d "$project_dir/backend" ]; then
            echo -e "${GREEN}✅ Detected GPT-RAG project structure${NC}"
            
            # Check frontend type
            if [ -f "$project_dir/frontend/package.json" ]; then
                if grep -q "\"@fluentui/react\":" "$project_dir/frontend/package.json" || \
                   grep -q "\"@azure/\":" "$project_dir/frontend/package.json" || \
                   grep -q "\"@microsoft/\":" "$project_dir/frontend/package.json"; then
                    echo -e "${GREEN}✅ Detected Azure UI React project${NC}"
                    echo "azure-react"
                    return 0
                fi
            fi
            
            # If not specifically Azure UI, check for React/TypeScript
            if [ -f "$project_dir/frontend/tsconfig.json" ]; then
                echo -e "${GREEN}✅ Detected React TypeScript project${NC}"
                echo "react-typescript"
                return 0
            fi
        fi
        
        # Check for monorepo structure without backend
        if [ -d "$project_dir/frontend" ]; then
            echo -e "${YELLOW}📂 Detected monorepo structure, checking frontend directory...${NC}"
            project_dir="$project_dir/frontend"
        fi
        
        # Check for Next.js projects first
        if [ -f "$project_dir/package.json" ]; then
            if grep -q "\"next\":" "$project_dir/package.json"; then
                echo -e "${GREEN}✅ Detected Next.js project${NC}"
                echo "nextjs"
                return 0
            fi
        fi
        
        # Check for TypeScript projects
        if [ -f "$project_dir/tsconfig.json" ]; then
            if [ -f "$project_dir/package.json" ]; then
                if grep -q "\"@types/react\":" "$project_dir/package.json" || grep -q "\"typescript\":" "$project_dir/package.json"; then
                    echo -e "${GREEN}✅ Detected React TypeScript project${NC}"
                    echo "react-typescript"
                    return 0
                fi
                echo -e "${GREEN}✅ Detected TypeScript project${NC}"
                echo "typescript"
                return 0
            fi
        fi
        
        # Check for React projects
        if [ -f "$project_dir/package.json" ]; then
            if grep -q "\"react\":" "$project_dir/package.json"; then
                echo -e "${GREEN}✅ Detected React project${NC}"
                echo "react"
                return 0
            fi
        fi
        
        # Check for Node.js/React/Vue/Angular projects
        if [ -f "$project_dir/package.json" ]; then
            echo -e "${GREEN}✅ Detected Node.js project${NC}"
            echo "nodejs"
            return 0
        fi
        
        # Check for Python projects
        if [ -f "$project_dir/requirements.txt" ] || [ -f "$project_dir/setup.py" ] || [ -f "$project_dir/pyproject.toml" ]; then
            echo -e "${GREEN}✅ Detected Python project${NC}"
            echo "python"
            return 0
        fi
        
        # Check for Java projects
        if [ -f "$project_dir/pom.xml" ] || [ -f "$project_dir/build.gradle" ]; then
            echo -e "${GREEN}✅ Detected Java project${NC}"
            echo "java"
            return 0
        fi
        
        # Check for C++ projects
        if [ -f "$project_dir/CMakeLists.txt" ] || [ -f "$project_dir/Makefile" ] || find "$project_dir" -name "*.cpp" -o -name "*.hpp" | grep -q .; then
            echo -e "${GREEN}✅ Detected C++ project${NC}"
            echo "cpp"
            return 0
        fi
        
        # Check for Rust projects
        if [ -f "$project_dir/Cargo.toml" ]; then
            echo -e "${GREEN}✅ Detected Rust project${NC}"
            echo "rust"
            return 0
        fi
        
        # Check for Go projects
        if [ -f "$project_dir/go.mod" ]; then
            echo -e "${GREEN}✅ Detected Go project${NC}"
            echo "golang"
            return 0
        fi
        
        # Check for frontend projects without package.json
        if [ -f "$project_dir/index.html" ] || [ -f "$project_dir/src/index.html" ] || [ -f "$project_dir/public/index.html" ]; then
            echo -e "${GREEN}✅ Detected frontend project${NC}"
            echo "frontend"
            return 0
        fi
        
        # If we get here, we couldn't detect the type
        echo -e "${RED}❌ Could not detect project type${NC}"
        echo -e "${YELLOW}💡 Project structure:${NC}"
        find "$project_dir" -type f -name "package.json" -o -name "tsconfig.json" -o -name "requirements.txt"
        echo -e "${YELLOW}💡 Supported project types:${NC}"
        echo "  - Azure UI React (package.json with @fluentui/react)"
        echo "  - Next.js (package.json with next dependency)"
        echo "  - React TypeScript (tsconfig.json + package.json with @types/react)"
        echo "  - React (package.json with react dependency)"
        echo "  - TypeScript (tsconfig.json + package.json)"
        echo "  - Node.js (package.json)"
        echo "  - Python (requirements.txt, setup.py, pyproject.toml)"
        echo "  - Java (pom.xml, build.gradle)"
        echo "  - C++ (CMakeLists.txt, Makefile, *.cpp)"
        echo "  - Rust (Cargo.toml)"
        echo "  - Go (go.mod)"
        echo "  - Frontend (index.html)"
        echo "unknown"
        return 1
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