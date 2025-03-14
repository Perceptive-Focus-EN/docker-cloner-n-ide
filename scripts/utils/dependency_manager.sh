#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to detect project type
detect_project_type() {
    local project_dir="$1"
    
    echo -e "${YELLOW}🔍 Detecting project type in: $project_dir${NC}"
    
    # First check if directory exists
    if [ ! -d "$project_dir" ]; then
        echo -e "${RED}❌ Project directory not found: $project_dir${NC}"
        echo "unknown"
        return 1
    fi
    
    # Check for Next.js projects first (they also have package.json but need special handling)
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
            echo -e "${GREEN}✅ Detected TypeScript project${NC}"
            echo "typescript"
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
    echo -e "${YELLOW}💡 Supported project types:${NC}"
    echo "  - Next.js (package.json with next dependency)"
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
}

# Function to install dependencies based on project type
install_dependencies() {
    local project_type="$1"
    local project_dir="$2"
    
    echo -e "${YELLOW}Installing dependencies for $project_type project...${NC}"
    
    case "$project_type" in
        "nextjs")
            # Install Node.js, npm and project dependencies
            apt-get update && apt-get install -y nodejs npm
            
            # Install global Next.js CLI
            npm install -g next
            
            # Install project dependencies
            if [ -f "$project_dir/package.json" ]; then
                cd "$project_dir" && npm install
                
                # Build the project
                npm run build
            fi
            ;;
            
        "typescript")
            # Install Node.js, npm and TypeScript
            apt-get update && apt-get install -y nodejs npm
            npm install -g typescript ts-node
            
            # Install project dependencies
            if [ -f "$project_dir/package.json" ]; then
                cd "$project_dir" && npm install
                
                # Build TypeScript project if build script exists
                if grep -q "\"build\":" "package.json"; then
                    npm run build
                else
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

# Export functions
export -f detect_project_type
export -f install_dependencies
export -f verify_installation 