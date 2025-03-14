#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to validate GitHub URL
validate_github_url() {
    local url="$1"
    if [[ ! "$url" =~ ^https://github.com/[^/]+/[^/]+(.git)?$ ]]; then
        echo -e "${RED}❌ Invalid GitHub URL format${NC}"
        echo -e "${YELLOW}💡 URL should be in format: https://github.com/username/repository${NC}"
        return 1
    fi
    return 0
}

# Function to detect default branch
detect_default_branch() {
    local url="$1"
    local default_branch
    
    # Remove color codes from output
    echo -e "${YELLOW}🔍 Detecting default branch...${NC}" >&2
    
    # Try to get the default branch directly from the API first
    if default_branch=$(git ls-remote --symref "$url" HEAD | awk '/^ref:/ {sub(/refs\/heads\//, "", $2); print $2}'); then
        echo -e "${GREEN}✅ Detected default branch: $default_branch${NC}" >&2
        echo "$default_branch"
        return 0
    fi
    
    # Fallback: try common branch names
    for branch in "main" "master" "development" "dev"; do
        if git ls-remote --exit-code --heads "$url" "$branch" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Detected default branch: $branch${NC}" >&2
            echo "$branch"
            return 0
        fi
    done
    
    echo -e "${RED}❌ Could not detect default branch${NC}" >&2
    return 1
}

# Function to clone repository
clone_repository() {
    local url="$1"
    local branch="$2"
    local target_dir="$3"
    
    echo -e "${YELLOW}📦 Cloning repository...${NC}"
    
    # Create target directory if it doesn't exist
    mkdir -p "$target_dir"
    
    # Clone the repository
    if git clone -b "$branch" "$url" "$target_dir"; then
        echo -e "${GREEN}✅ Repository cloned successfully${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to clone repository${NC}"
        return 1
    fi
}

# Function to check repository type
detect_repo_type() {
    local repo_path="$1"
    
    echo -e "${YELLOW}🔍 Detecting repository type...${NC}"
    
    # Check for various project types
    if [ -f "$repo_path/package.json" ]; then
        echo "nodejs"
    elif [ -f "$repo_path/requirements.txt" ] || [ -f "$repo_path/setup.py" ]; then
        echo "python"
    elif [ -f "$repo_path/pom.xml" ] || [ -f "$repo_path/build.gradle" ]; then
        echo "java"
    elif [ -f "$repo_path/CMakeLists.txt" ] || find "$repo_path" -name "*.cpp" -o -name "*.hpp" | grep -q .; then
        echo "cpp"
    elif [ -f "$repo_path/Cargo.toml" ]; then
        echo "rust"
    elif [ -f "$repo_path/go.mod" ]; then
        echo "golang"
    else
        echo "unknown"
    fi
}

# Function to handle GitHub operations
handle_github() {
    local url="$1"
    local target_dir="$2"
    
    # Validate URL
    validate_github_url "$url" || return 1
    
    # Detect default branch
    local branch=$(detect_default_branch "$url")
    [ $? -eq 0 ] || return 1
    
    # Clone repository
    clone_repository "$url" "$branch" "$target_dir" || return 1
    
    # Detect repository type
    local repo_type=$(detect_repo_type "$target_dir")
    echo -e "${GREEN}✅ Detected repository type: $repo_type${NC}"
    
    echo "$repo_type"
    return 0
}

# Export functions
export -f validate_github_url
export -f detect_default_branch
export -f clone_repository
export -f detect_repo_type
export -f handle_github 