#!/bin/bash

# Detect environment before proceeding
detect_environment

# Function to detect OS and shell environment
detect_environment() {
    echo "Detecting environment..."
    
    # Detect OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS_TYPE="linux"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        OS_TYPE="windows"
    else
        OS_TYPE="unknown"
    fi
    
    # Detect shell
    SHELL_TYPE=$(basename "$SHELL")
    
    # Detect Docker availability
    if command -v docker &> /dev/null; then
        DOCKER_AVAILABLE=true
    else
        DOCKER_AVAILABLE=false
    fi
    
    # Detect Git availability
    if command -v git &> /dev/null; then
        GIT_AVAILABLE=true
    else
        GIT_AVAILABLE=false
    fi
    
    # Detect Python availability
    if command -v python3 &> /dev/null; then
        PYTHON_AVAILABLE=true
        PYTHON_VERSION=$(python3 --version)
    else
        PYTHON_AVAILABLE=false
    fi
    
    # Print environment information
    echo "Environment Information:"
    echo "OS Type: $OS_TYPE"
    echo "Shell Type: $SHELL_TYPE"
    echo "Docker Available: $DOCKER_AVAILABLE"
    echo "Git Available: $GIT_AVAILABLE"
    echo "Python Available: $PYTHON_AVAILABLE"
    if [ "$PYTHON_AVAILABLE" = true ]; then
        echo "Python Version: $PYTHON_VERSION"
    fi
    
    # Check for required dependencies
    if [ "$DOCKER_AVAILABLE" = false ]; then
        echo "Error: Docker is not installed. Please install Docker first."
        echo "Visit https://docs.docker.com/get-docker/ for installation instructions."
        exit 1
    fi
    
    if [ "$GIT_AVAILABLE" = false ]; then
        echo "Error: Git is not installed. Please install Git first."
        case $OS_TYPE in
            "macos")
                echo "You can install Git using Homebrew: brew install git"
                ;;
            "linux")
                echo "You can install Git using your package manager:"
                echo "Ubuntu/Debian: sudo apt-get install git"
                echo "Fedora: sudo dnf install git"
                echo "CentOS: sudo yum install git"
                ;;
            "windows")
                echo "You can install Git from: https://git-scm.com/download/win"
                ;;
        esac
        exit 1
    fi
}

# Function to setup OS-specific requirements
setup_os_requirements() {
    local container_name="$1"
    
    case $OS_TYPE in
        "macos")
            # macOS specific setup
            echo "Setting up macOS specific requirements..."
            # Add any macOS specific container configurations here
            ;;
        "linux")
            # Linux specific setup
            echo "Setting up Linux specific requirements..."
            # Add any Linux specific container configurations here
            ;;
        "windows")
            # Windows specific setup
            echo "Setting up Windows specific requirements..."
            # Add any Windows specific container configurations here
            ;;
    esac
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

# Function to create a container with OS-specific settings
create_container() {
    local container_name="$1"
    
    # Check if container exists
    if container_exists "$container_name"; then
        read -p "Container $container_name already exists. Do you want to update it? (y/n): " update
        if [ "$update" != "y" ]; then
            return 1
        fi
    fi
    
    # Stop and remove existing container if it's running
    if container_running "$container_name"; then
        echo "Stopping existing container..."
        docker stop "$container_name"
        docker rm "$container_name"
    fi
    
    # Create new container with OS-specific settings
    echo "Creating new container..."
    case $OS_TYPE in
        "macos")
            # macOS specific container creation
            docker run -d --name "$container_name" \
                -v /tmp:/tmp \
                -e TZ=$(systemsetup -gettimezone | awk '{print $2}') \
                ubuntu:latest tail -f /dev/null
            ;;
        "linux")
            # Linux specific container creation
            docker run -d --name "$container_name" \
                -v /tmp:/tmp \
                -e TZ=$(cat /etc/timezone) \
                ubuntu:latest tail -f /dev/null
            ;;
        "windows")
            # Windows specific container creation
            docker run -d --name "$container_name" \
                -v /tmp:/tmp \
                -e TZ=$(powershell -Command "[System.TimeZoneInfo]::Local.Id") \
                ubuntu:latest tail -f /dev/null
            ;;
        *)
            # Default container creation
            docker run -d --name "$container_name" \
                -v /tmp:/tmp \
                ubuntu:latest tail -f /dev/null
            ;;
    esac
    
    # Wait for container to be ready
    sleep 2
    
    # Install unzip in container
    docker exec "$container_name" apt-get update
    docker exec "$container_name" apt-get install -y unzip
    
    # Setup OS-specific requirements
    setup_os_requirements "$container_name"
}

# Function to setup environment based on repository type
setup_environment() {
    local repo_path="$1"
    local container_name="$2"
    echo "Setting up environment..."
    
    # Check for Python project
    if [ -f "$repo_path/requirements.txt" ] || [ -f "$repo_path/pyproject.toml" ] || [ -f "$repo_path/setup.py" ]; then
        echo "Detected Python project, setting up Python environment..."
        docker exec "$container_name" bash -c '
            apt-get update && \
            apt-get install -y python3 python3-pip python3-venv && \
            python3 -m venv /tmp/venv && \
            source /tmp/venv/bin/activate && \
            pip install --upgrade pip && \
            if [ -f /tmp/repo/requirements.txt ]; then pip install -r /tmp/repo/requirements.txt; fi && \
            if [ -f /tmp/repo/pyproject.toml ]; then pip install poetry && poetry install; fi && \
            if [ -f /tmp/repo/setup.py ]; then pip install -e .; fi
        '
    fi
    
    # Check for Node.js project
    if [ -f "$repo_path/package.json" ]; then
        echo "Detected Node.js project, setting up Node.js environment..."
        docker exec "$container_name" bash -c '
            apt-get update && \
            apt-get install -y npm && \
            cd /tmp/repo && \
            npm install
        '
    fi
    
    # Check for Go project
    if [ -f "$repo_path/go.mod" ]; then
        echo "Detected Go project, setting up Go environment..."
        docker exec "$container_name" bash -c '
            apt-get update && \
            apt-get install -y golang-go && \
            cd /tmp/repo && \
            go mod download
        '
    fi
    
    # Check for Rust project
    if [ -f "$repo_path/Cargo.toml" ]; then
        echo "Detected Rust project, setting up Rust environment..."
        docker exec "$container_name" bash -c '
            apt-get update && \
            apt-get install -y curl && \
            curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
            source $HOME/.cargo/env && \
            cd /tmp/repo && \
            cargo build
        '
    fi
    
    # Check for Ruby project
    if [ -f "$repo_path/Gemfile" ]; then
        echo "Detected Ruby project, setting up Ruby environment..."
        docker exec "$container_name" bash -c '
            apt-get update && \
            apt-get install -y ruby ruby-dev build-essential && \
            gem install bundler && \
            cd /tmp/repo && \
            bundle install
        '
    fi
    
    # Check for PHP project
    if [ -f "$repo_path/composer.json" ]; then
        echo "Detected PHP project, setting up PHP environment..."
        docker exec "$container_name" bash -c '
            apt-get update && \
            apt-get install -y php php-cli php-mbstring unzip && \
            curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
            cd /tmp/repo && \
            composer install
        '
    fi
    
    # Check for Java/Maven project
    if [ -f "$repo_path/pom.xml" ]; then
        echo "Detected Java/Maven project, setting up Java environment..."
        docker exec "$container_name" bash -c '
            apt-get update && \
            apt-get install -y openjdk-17-jdk maven && \
            cd /tmp/repo && \
            mvn install
        '
    fi
    
    # Check for .NET project
    if [ -f "$repo_path/*.csproj" ] || [ -f "$repo_path/*.fsproj" ]; then
        echo "Detected .NET project, setting up .NET environment..."
        docker exec "$container_name" bash -c '
            apt-get update && \
            apt-get install -y wget && \
            wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb && \
            dpkg -i packages-microsoft-prod.deb && \
            apt-get update && \
            apt-get install -y dotnet-sdk-7.0 && \
            cd /tmp/repo && \
            dotnet restore && \
            dotnet build
        '
    fi
    
    echo "Environment setup complete!"
}

# Function to copy and extract repository
copy_and_extract_repo() {
    local repo_dir="$1"
    local container_name="$2"
    
    # Create zip file
    local zip_file="/tmp/repo.zip"
    cd "$repo_dir" && zip -r "$zip_file" . && cd -
    
    # Copy zip to container
    docker cp "$zip_file" "$container_name:/tmp/"
    
    # Create directory and extract in container
    docker exec "$container_name" mkdir -p /tmp/repo
    docker exec "$container_name" unzip -o /tmp/repo.zip -d /tmp/repo/
    
    # Setup environment based on repository type
    setup_environment "$repo_dir" "$container_name"
    
    # Cleanup zip file
    rm "$zip_file"
    docker exec "$container_name" rm /tmp/repo.zip
}

# Function to copy and extract zip file
copy_and_extract_zip() {
    local zip_path="$1"
    local container_name="$2"
    
    # Copy zip to container
    docker cp "$zip_path" "$container_name:/tmp/repo.zip"
    
    # Create directory and extract in container
    docker exec "$container_name" mkdir -p /tmp/repo
    docker exec "$container_name" unzip -o /tmp/repo.zip -d /tmp/repo/
    
    # Setup environment based on repository type
    setup_environment "$zip_path" "$container_name"
    
    # Cleanup zip file
    docker exec "$container_name" rm /tmp/repo.zip
}

# Function to clone repository and setup container
clone_repository() {
    local github_url="$1"
    local branch="$2"
    local container_name="$3"
    local temp_dir=$(mktemp -d)
    local repo_name=$(basename "$github_url" .git)
    
    echo "Created temporary directory: $temp_dir"
    echo "Cloning repository..."
    
    if ! git clone -b "$branch" "$github_url" "$temp_dir/repo"; then
        echo "Error: Failed to clone repository"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Create container
    create_container "$container_name"
    
    # Copy and extract repository
    copy_and_extract_repo "$temp_dir/repo" "$container_name"
    
    # Setup environment based on repository type
    setup_environment "$temp_dir/repo" "$container_name"
    
    # Cleanup
    rm -rf "$temp_dir"
    echo "Repository setup complete!"
}

# Default repositories
DEFAULT_REPOS=(
    "fastapi=https://github.com/tiangolo/fastapi.git"
    "flask=https://github.com/pallets/flask.git"
    "django=https://github.com/django/django.git"
    "pytorch=https://github.com/pytorch/pytorch.git"
    "tensorflow=https://github.com/tensorflow/tensorflow.git"
)

# Function to get valid input
get_valid_input() {
    local prompt="$1"
    local default="$2"
    local input
    
    while true; do
        read -r -p "$prompt" input
        input=${input:-$default}
        if [ -n "$input" ]; then
            echo "$input"
            return 0
        fi
        echo "Input cannot be empty. Please try again."
    done
}

# Function to get valid number input
get_valid_number() {
    local prompt="$1"
    local min="$2"
    local max="$3"
    local input
    
    while true; do
        read -r -p "$prompt" input
        if [[ "$input" =~ ^[0-9]+$ ]] && [ "$input" -ge "$min" ] && [ "$input" -le "$max" ]; then
            echo "$input"
            return 0
        fi
        echo "Please enter a number between $min and $max"
    done
}

# Function to get file path with proper validation
get_file_path() {
    local prompt="$1"
    local file_type="$2"
    local file_path
    
    # Show instructions first
    echo "----------------------------------------"
    echo "File Selection Options:"
    echo "1. Drag and drop a ZIP file into this terminal window"
    echo "2. Click the file dialog button (if available)"
    echo "3. Type or paste the file path manually"
    echo "----------------------------------------"
    
    # Try GUI dialog first if available
    case $OS_TYPE in
        "macos")
            if command -v osascript &> /dev/null; then
                echo "Opening macOS file dialog..."
                file_path=$(osascript -e 'tell application "System Events"
                    activate
                    set theFile to choose file with prompt "Select ZIP file" of type {"zip", "ZIP"} with invisibles
                    return POSIX path of theFile
                end tell' 2>/dev/null)
            fi
            ;;
        "linux")
            if command -v zenity &> /dev/null; then
                echo "Opening Linux file dialog (zenity)..."
                file_path=$(zenity --file-selection --file-filter="ZIP files (*.zip)" --title="Select ZIP file")
            elif command -v kdialog &> /dev/null; then
                echo "Opening Linux file dialog (kdialog)..."
                file_path=$(kdialog --getopenfilename --filefilter "ZIP files (*.zip)")
            fi
            ;;
        "windows")
            if command -v powershell &> /dev/null; then
                echo "Opening Windows file dialog..."
                file_path=$(powershell -Command "Add-Type -AssemblyName System.Windows.Forms; \$f=New-Object System.Windows.Forms.OpenFileDialog; \$f.Filter='ZIP files (*.zip)|*.zip'; \$f.ShowDialog(); \$f.FileName")
            fi
            ;;
    esac
    
    # If no GUI dialog was available or if it failed, handle drag and drop or manual input
    if [ -z "$file_path" ]; then
        echo "No GUI file dialog available or dialog cancelled."
        echo "You can drag and drop a ZIP file here or type the path manually:"
        read -r -p "$prompt" file_path
        
        # Handle drag and drop (remove quotes if present)
        file_path=$(echo "$file_path" | sed -e 's/^"//' -e 's/"$//')
    fi
    
    # Validate file path
    if [ -n "$file_path" ]; then
        # Convert to absolute path based on OS
        case $OS_TYPE in
            "macos"|"linux")
                file_path=$(realpath "$file_path" 2>/dev/null || echo "$file_path")
                ;;
            "windows")
                file_path=$(powershell -Command "[System.IO.Path]::GetFullPath('$file_path')" 2>/dev/null || echo "$file_path")
                ;;
        esac
        
        # Check if file exists and is readable
        if [ -f "$file_path" ]; then
            # Check file permissions
            if [ ! -r "$file_path" ]; then
                echo "Error: No permission to read this file. Please check file permissions."
                return 1
            fi
            
            # Validate file type based on OS
            case $OS_TYPE in
                "macos")
                    if file "$file_path" | grep -q "Zip archive"; then
                        echo "Selected file: $file_path"
                        echo "$file_path"
                        return 0
                    fi
                    ;;
                "linux")
                    if file "$file_path" | grep -q "Zip archive"; then
                        echo "Selected file: $file_path"
                        echo "$file_path"
                        return 0
                    fi
                    ;;
                "windows")
                    if [[ "$file_path" =~ \.zip$ ]]; then
                        echo "Selected file: $file_path"
                        echo "$file_path"
                        return 0
                    fi
                    ;;
            esac
            echo "Error: Selected file is not a valid ZIP archive"
        else
            echo "Error: File not found"
        fi
    fi
    
    return 1
}

# Function to display menu
show_menu() {
    clear
    echo "=== GitHub Repository to Container Manager ==="
    echo "1. Clone from default repositories"
    echo "2. Clone from custom GitHub URL"
    echo "3. Upload and extract ZIP file"
    echo "4. Use existing cloned repository"
    echo "5. Exit"
    echo "==========================================="
}

# Function to display default repositories
show_default_repos() {
    echo "Available default repositories:"
    local i=1
    for repo in "${DEFAULT_REPOS[@]}"; do
        name="${repo%%=*}"
        echo "$i. $name"
        ((i++))
    done
    echo "0. Back to main menu"
}

# Main loop
while true; do
    show_menu
    choice=$(get_valid_number "Select an option (1-5): " 1 5)
    
    case $choice in
        1)
            show_default_repos
            repo_num=$(get_valid_number "Select repository number (0 to go back): " 0 "${#DEFAULT_REPOS[@]}")
            if [ "$repo_num" = "0" ]; then
                continue
            fi
            
            # Get repository URL from selection
            i=1
            for repo in "${DEFAULT_REPOS[@]}"; do
                if [ "$i" = "$repo_num" ]; then
                    name="${repo%%=*}"
                    url="${repo##*=}"
                    container_name=$(get_valid_input "Enter container name (default: $name): " "$name")
                    branch_name=$(get_valid_input "Enter branch name (default: master): " "master")
                    clone_repository "$url" "$branch_name" "$container_name"
                    break
                fi
                ((i++))
            done
            ;;
            
        2)
            url=$(get_valid_input "Enter GitHub repository URL: " "")
            if [ -z "$url" ]; then
                echo "Error: GitHub URL is required"
                continue
            fi
            
            # Extract default container name from URL
            default_name=$(basename "$url" .git)
            container_name=$(get_valid_input "Enter container name (default: $default_name): " "$default_name")
            branch_name=$(get_valid_input "Enter branch name (default: master): " "master")
            
            clone_repository "$url" "$branch_name" "$container_name"
            ;;
            
        3)
            echo "=== Upload and Extract ZIP File ==="
            echo "Please select a ZIP file to upload..."
            while true; do
                zip_path=$(get_file_path "Enter path to ZIP file: " "zip")
                if [ -n "$zip_path" ]; then
                    break
                fi
                echo "Please try again or press Ctrl+C to cancel"
            done
            
            default_name=$(basename "$zip_path" .zip)
            container_name=$(get_valid_input "Enter container name (default: $default_name): " "$default_name")
            
            create_container "$container_name"
            copy_and_extract_zip "$zip_path" "$container_name"
            ;;
            
        4)
            echo "Available repositories in current directory:"
            ls -d */ 2>/dev/null | sed 's/\/$//'
            
            repo_dir=$(get_valid_input "Enter repository directory name: " "")
            if [ ! -d "$repo_dir" ]; then
                echo "Error: Repository directory not found"
                continue
            fi
            
            container_name=$(get_valid_input "Enter container name (default: $repo_dir): " "$repo_dir")
            
            create_container "$container_name"
            copy_and_extract_repo "$repo_dir" "$container_name"
            ;;
            
        5)
            echo "Exiting..."
            exit 0
            ;;
    esac
    
    echo
    read -r -p "Press Enter to continue..."
done 