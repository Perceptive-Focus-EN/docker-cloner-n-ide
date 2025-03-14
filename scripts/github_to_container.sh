#!/bin/bash

# Detect environment before proceeding
detect_environment

# Function to check Docker Desktop status on macOS
check_docker_desktop_status() {
    if [ "$OS_TYPE" = "macos" ]; then
        # Check if Docker.app exists
        if [ ! -d "/Applications/Docker.app" ]; then
            echo "not_installed"
            return
        fi
        
        # Check if Docker Desktop process is running
        if pgrep -x "Docker" >/dev/null; then
            # Check if Docker daemon is responsive
            if ! docker info >/dev/null 2>&1; then
                echo "starting"
            else
                echo "running"
            fi
        else
            echo "installed"
        fi
    fi
}

# Function to start Docker Desktop on macOS with proper permissions
start_docker_desktop_macos() {
    echo "🔍 Checking Docker Desktop permissions..."
    
    # First try using AppleScript to check if we can interact with Docker Desktop
    osascript <<EOF >/dev/null 2>&1
        tell application "System Events"
            try
                tell process "Docker Desktop"
                    return true
                end tell
            on error
                return false
            end try
        end tell
EOF
    
    if [ $? -ne 0 ]; then
        echo "❌ Script needs permission to control Docker Desktop"
        echo "💡 Please grant permission in System Preferences:"
        echo "   1. Open System Preferences"
        echo "   2. Go to Security & Privacy → Privacy → Automation"
        echo "   3. Find Terminal or your terminal app"
        echo "   4. Enable permissions for Docker Desktop"
        
        # Ask user to open System Preferences
        read -p "Would you like to open System Preferences now? (y/n): " open_prefs
        if [ "$open_prefs" = "y" ]; then
            open "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"
            echo "⏳ Please grant permissions and press Enter to continue..."
            read -r
        else
            echo "💡 Please grant permissions manually and run the script again"
            exit 1
        fi
    fi
    
    echo "🐳 Starting Docker Desktop..."
    
    # Try to start Docker Desktop using AppleScript
    osascript <<EOF
        tell application "Docker Desktop"
            activate
        end tell
EOF
    
    # Wait for Docker to start
    echo "⏳ Waiting for Docker to start (this may take a minute)..."
    local attempts=0
    while [ $attempts -lt 60 ]; do  # Increased timeout to 2 minutes
        if docker info >/dev/null 2>&1; then
            echo "✅ Docker Desktop is now running!"
            return 0
        fi
        sleep 2
        ((attempts++))
        if [ $((attempts % 5)) -eq 0 ]; then
            echo -n "Still waiting for Docker to start..."
        else
            echo -n "."
        fi
    done
    
    echo
    echo "❌ Timed out waiting for Docker to start"
    echo "💡 Tips:"
    echo "   - Check if Docker Desktop is running in your menu bar"
    echo "   - Try starting Docker Desktop manually from Applications"
    echo "   - Check Docker Desktop preferences for any startup issues"
    return 1
}

# Function to start Docker Desktop on Windows with proper permissions
start_docker_desktop_windows() {
    echo "🔍 Checking Docker Desktop permissions..."
    
    # Check if running with admin privileges
    net session >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "❌ Script needs administrator privileges"
        echo "💡 Please run the script as Administrator:"
        echo "   1. Right-click on Terminal/PowerShell"
        echo "   2. Select 'Run as administrator'"
        exit 1
    fi
    
    # Check if Docker Desktop path exists
    local docker_path="/c/Program Files/Docker/Docker/Docker Desktop.exe"
    if [ ! -f "$docker_path" ]; then
        docker_path="/d/Program Files/Docker/Docker/Docker Desktop.exe"
        if [ ! -f "$docker_path" ]; then
            echo "❌ Cannot find Docker Desktop executable"
            echo "💡 Please check if Docker Desktop is installed correctly"
            exit 1
        fi
    fi
    
    echo "🐳 Starting Docker Desktop..."
    
    # Try to start Docker Desktop using PowerShell
    powershell.exe -Command "Start-Process '$docker_path'" &
    
    # Wait for Docker to start
    echo "⏳ Waiting for Docker to start (this may take a minute)..."
    local attempts=0
    while [ $attempts -lt 60 ]; do  # 2 minute timeout
        if docker info >/dev/null 2>&1; then
            echo "✅ Docker Desktop is now running!"
            return 0
        fi
        sleep 2
        ((attempts++))
        if [ $((attempts % 5)) -eq 0 ]; then
            echo -n "Still waiting for Docker to start..."
        else
            echo -n "."
        fi
    done
    
    echo
    echo "❌ Timed out waiting for Docker to start"
    echo "💡 Tips:"
    echo "   - Check if Docker Desktop is running in the system tray"
    echo "   - Try starting Docker Desktop manually from Start Menu"
    echo "   - Check Docker Desktop settings for any startup issues"
    echo "   - Run the Docker Desktop troubleshooter"
    return 1
}

# Function to start Docker daemon on Linux with proper permissions
start_docker_daemon_linux() {
    echo "🔍 Checking Docker permissions..."
    
    # Check if user is in docker group
    if ! groups | grep -q docker; then
        echo "❌ User is not in the docker group"
        echo "💡 Would you like to:"
        echo "   1. Add current user to docker group (recommended)"
        echo "   2. Use sudo to start Docker daemon"
        echo "   3. Cancel"
        read -p "Select option (1-3): " docker_option
        
        case $docker_option in
            1)
                echo "Adding user to docker group..."
                if sudo usermod -aG docker "$USER"; then
                    echo "✅ User added to docker group"
                    echo "💡 Please log out and log back in for changes to take effect"
                    exit 0
                else
                    echo "❌ Failed to add user to docker group"
                fi
                ;;
            2)
                echo "Using sudo to start Docker..."
                ;;
            *)
                echo "Operation cancelled"
                exit 1
                ;;
        esac
    fi
    
    echo "🐳 Starting Docker daemon..."
    
    # Try systemd first, then service
    if command -v systemctl >/dev/null 2>&1; then
        echo "Using systemd to start Docker..."
        if ! sudo systemctl start docker; then
            echo "❌ Failed to start Docker daemon using systemd"
            echo "💡 Trying alternative method..."
            if ! sudo service docker start; then
                echo "❌ Failed to start Docker daemon"
                echo "💡 Tips:"
                echo "   - Check Docker installation: sudo systemctl status docker"
                echo "   - Check system logs: journalctl -xe"
                echo "   - Try reinstalling Docker"
                return 1
            fi
        fi
    else
        echo "Using service to start Docker..."
        if ! sudo service docker start; then
            echo "❌ Failed to start Docker daemon"
            echo "💡 Tips:"
            echo "   - Check Docker service status: service docker status"
            echo "   - Check system logs: tail -f /var/log/syslog"
            echo "   - Try reinstalling Docker"
            return 1
        fi
    fi
    
    # Wait for Docker to be responsive
    echo "⏳ Waiting for Docker daemon to be ready..."
    local attempts=0
    while [ $attempts -lt 30 ]; do
        if docker info >/dev/null 2>&1; then
            echo "✅ Docker daemon is now running!"
            return 0
        fi
        sleep 2
        ((attempts++))
        if [ $((attempts % 5)) -eq 0 ]; then
            echo -n "Still waiting for Docker daemon..."
        else
            echo -n "."
        fi
    done
    
    echo
    echo "❌ Docker daemon started but not responding"
    echo "💡 Tips:"
    echo "   - Check Docker daemon status: sudo systemctl status docker"
    echo "   - Check system logs: journalctl -xe"
    echo "   - Verify docker.sock permissions: ls -l /var/run/docker.sock"
    return 1
}

# Function to start Docker Desktop
start_docker_desktop() {
    case $OS_TYPE in
        "macos")
            start_docker_desktop_macos
            ;;
        "linux")
            start_docker_daemon_linux
            ;;
        "windows")
            start_docker_desktop_windows
            ;;
    esac
}

# Function to detect OS and shell environment
detect_environment() {
    echo "🔍 Detecting environment..."
    
    # Detect OS first
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS_TYPE="linux"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        OS_TYPE="windows"
    else
        OS_TYPE="unknown"
    fi
    
    # Check Docker installation and status
    if ! command -v docker >/dev/null 2>&1; then
        echo "❌ Docker is not installed"
        echo "💡 Please install Docker Desktop:"
        case $OS_TYPE in
            "macos")
                echo "   Visit: https://www.docker.com/products/docker-desktop"
                echo "   Or install with Homebrew: brew install --cask docker"
                ;;
            "linux")
                echo "   Run: curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh"
                ;;
            "windows")
                echo "   Visit: https://www.docker.com/products/docker-desktop"
                ;;
        esac
        exit 1
    fi
    
    # Check Docker status and handle startup
    if ! docker info >/dev/null 2>&1; then
        case $OS_TYPE in
            "macos")
                status=$(check_docker_desktop_status)
                case $status in
                    "installed")
                        echo "🐳 Docker Desktop is installed but not running"
                        read -p "Would you like to start Docker Desktop now? (y/n): " start_docker
                        if [ "$start_docker" = "y" ]; then
                            if ! start_docker_desktop; then
                                echo "❌ Failed to start Docker Desktop"
                                echo "💡 Try starting Docker Desktop manually from Applications"
                                exit 1
                            fi
                        else
                            echo "💡 Please start Docker Desktop manually when ready"
                            exit 1
                        fi
                        ;;
                    "starting")
                        echo "⏳ Docker Desktop is starting up..."
                        echo "💡 Please wait for Docker Desktop to finish starting"
                        exit 1
                        ;;
                    "not_installed")
                        echo "❌ Docker Desktop is not installed"
                        echo "💡 Please install Docker Desktop from:"
                        echo "   https://www.docker.com/products/docker-desktop"
                        exit 1
                        ;;
                esac
                ;;
            "linux")
                echo "🐳 Docker daemon is not running"
                if [ "$EUID" -ne 0 ]; then
                    echo "💡 Starting Docker daemon requires sudo privileges"
                    read -p "Would you like to start Docker daemon now? (y/n): " start_docker
                    if [ "$start_docker" = "y" ]; then
                        if ! start_docker_desktop; then
                            echo "❌ Failed to start Docker daemon"
                            echo "💡 Try running: sudo systemctl start docker"
                            exit 1
                        fi
                    else
                        echo "💡 Please start Docker daemon manually when ready"
                        exit 1
                    fi
                fi
                ;;
            "windows")
                echo "🐳 Docker Desktop is not running"
                read -p "Would you like to start Docker Desktop now? (y/n): " start_docker
                if [ "$start_docker" = "y" ]; then
                    if ! start_docker_desktop; then
                        echo "❌ Failed to start Docker Desktop"
                        echo "💡 Try starting Docker Desktop manually from the Start Menu"
                        exit 1
                    fi
                else
                    echo "💡 Please start Docker Desktop manually when ready"
                    exit 1
                fi
                ;;
        esac
    fi
    
    echo "✅ Docker is running and ready!"
    
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

# Function to detect GPT-RAG frontend project
detect_gpt_rag_frontend() {
    local repo_path="$1"
    
    # Check for frontend and backend directories
    if [ -d "$repo_path/frontend" ] && [ -d "$repo_path/backend" ]; then
        # Check for package.json in frontend directory
        if [ -f "$repo_path/frontend/package.json" ]; then
            # Check if it's a Vite or React project
            if grep -q "\"vite\"" "$repo_path/frontend/package.json" || grep -q "\"react\"" "$repo_path/frontend/package.json"; then
                return 0 # It's a GPT-RAG frontend project
            fi
        fi
    fi
    
    return 1 # Not a GPT-RAG frontend project
}

# Function to create a container with OS-specific settings
create_container() {
    local container_name="$1"
    local repo_path="$2"
    local is_gpt_rag=false
    
    # Check if it's a GPT-RAG frontend project
    if [ -n "$repo_path" ] && detect_gpt_rag_frontend "$repo_path"; then
        is_gpt_rag=true
        echo "📦 Detected GPT-RAG frontend project - will expose ports automatically"
    fi
    
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
    
    # Base docker run command
    local docker_run_cmd="docker run -d --name \"$container_name\""
    
    # Add port mappings for GPT-RAG frontend projects
    if [ "$is_gpt_rag" = true ]; then
        docker_run_cmd+=" -p 8000:8000 -p 3000:3000 -p 5000:5000"
        echo "🔌 Exposing ports: 8000, 3000, 5000 for GPT-RAG frontend"
    fi
    
    case $OS_TYPE in
        "macos")
            # macOS specific container creation
            eval "$docker_run_cmd \
                -v /tmp:/tmp \
                -e TZ=$(systemsetup -gettimezone | awk '{print $2}') \
                ubuntu:latest tail -f /dev/null"
            ;;
        "linux")
            # Linux specific container creation
            eval "$docker_run_cmd \
                -v /tmp:/tmp \
                -e TZ=$(cat /etc/timezone) \
                ubuntu:latest tail -f /dev/null"
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
    
    # Check for C++ project
    if [ -f "$repo_path/CMakeLists.txt" ] || [ -f "$repo_path/Makefile" ] || find "$repo_path" -name "*.cpp" -o -name "*.hpp" -o -name "*.h" | grep -q .; then
        echo "Detected C++ project, setting up C++ environment..."
        docker exec "$container_name" bash -c '
            apt-get update && \
            apt-get install -y build-essential cmake g++ gdb ninja-build ccache \
                             libboost-all-dev libssl-dev pkg-config && \
            cd /tmp/repo && \
            if [ -f "CMakeLists.txt" ]; then
                mkdir -p build && cd build && \
                cmake .. && \
                make -j$(nproc)
            elif [ -f "Makefile" ]; then
                make -j$(nproc)
            else
                # If no build system, try to compile main.cpp or first found cpp file
                MAIN_CPP=$(find . -name "main.cpp" -o -name "*.cpp" | head -n 1)
                if [ -n "$MAIN_CPP" ]; then
                    g++ -std=c++17 -O2 "$MAIN_CPP" -o program
                fi
            fi
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
    
    echo "📦 Processing ZIP file..."
    
    # Create a temporary directory for extraction
    local temp_dir=$(mktemp -d)
    echo "📂 Created temporary directory for extraction"
    
    # Try to unzip the file
    if unzip -q "$zip_path" -d "$temp_dir"; then
        echo "✅ Successfully extracted ZIP file"
        
        # Copy contents to container
        echo "📤 Copying files to container..."
        docker cp "$temp_dir/." "$container_name:/tmp/repo/"
        
        # Cleanup temp directory
        rm -rf "$temp_dir"
        echo "🧹 Cleaned up temporary files"
        
        # Setup environment based on repository type
        setup_environment "/tmp/repo" "$container_name"
    else
        echo "❌ Failed to extract ZIP file"
        echo "💡 Tip: Make sure the file is a valid ZIP archive"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Function to handle ZIP file selection
get_file_path() {
    local prompt="$1"
    
    clear
    echo "=== Upload and Extract ZIP File ==="
    echo "----------------------------------------"
    echo "💡 Quick Tip: You can:"
    echo "  1. Drag & drop your ZIP file here"
    echo "  2. Copy & paste the file path"
    echo "  3. Type the path manually"
    echo "----------------------------------------"
    
    while true; do
        echo -n "➡️  Drop your ZIP file here: "
        read -r zip_path
        
        # Remove quotes if present (from drag and drop)
        zip_path=$(echo "$zip_path" | sed -e 's/^["'"'"']//' -e 's/["'"'"']$//')
        
        # Basic validation
        if [ ! -f "$zip_path" ]; then
            echo "❌ File not found: $zip_path"
            echo "💡 Tip: Make sure you provided the correct path"
            continue
        fi
        
        if [ ! -r "$zip_path" ]; then
            echo "❌ Cannot read file (permission denied)"
            echo "💡 Tip: Try running: chmod +r \"$zip_path\""
            continue
        fi
        
        # Try to peek inside the ZIP file
        if unzip -l "$zip_path" &>/dev/null; then
            # Show ZIP contents
            echo "📋 ZIP contents:"
            unzip -l "$zip_path" | tail -n +4 | head -n -2 | awk '{print "   " $4}'
            echo "----------------------------------------"
            echo "✅ Valid ZIP file detected"
            break
        else
            echo "❌ Not a valid ZIP file"
            echo "💡 Tip: Make sure you selected a ZIP file"
            continue
        fi
    done
    
    echo "$zip_path"
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
    
    # Try to detect default branch
    if ! git clone -b "$branch" "$github_url" "$temp_dir/repo" 2>/dev/null; then
        echo "Branch '$branch' not found, trying 'main'..."
        if ! git clone -b main "$github_url" "$temp_dir/repo" 2>/dev/null; then
            echo "Branch 'main' not found, trying 'master'..."
            if ! git clone -b master "$github_url" "$temp_dir/repo"; then
                echo "❌ Error: Failed to clone repository"
                echo "💡 Tip: Make sure the repository URL is correct and accessible"
                rm -rf "$temp_dir"
                return 1
            fi
        fi
    fi
    
    # Create container
    create_container "$container_name" "$temp_dir/repo"
    
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
            clear
            echo "=== Upload and Extract ZIP File ==="
            echo "----------------------------------------"
            echo "💡 Quick Tip: You can:"
            echo "  1. Drag & drop your ZIP file here"
            echo "  2. Copy & paste the file path"
            echo "  3. Type the path manually"
            echo "----------------------------------------"
            
            while true; do
                echo -n "➡️  Drop your ZIP file here: "
                read -r zip_path
                
                # Remove quotes if present (from drag and drop)
                zip_path=$(echo "$zip_path" | sed -e 's/^["'"'"']//' -e 's/["'"'"']$//')
                
                # Basic validation
                if [ ! -f "$zip_path" ]; then
                    echo "❌ File not found: $zip_path"
                    echo "💡 Tip: Make sure you provided the correct path"
                    continue
                fi
                
                if [ ! -r "$zip_path" ]; then
                    echo "❌ Cannot read file (permission denied)"
                    echo "💡 Tip: Try running: chmod +r \"$zip_path\""
                    continue
                fi
                
                # Try to peek inside the ZIP file
                if unzip -l "$zip_path" &>/dev/null; then
                    # Show ZIP contents
                    echo "📋 ZIP contents:"
                    unzip -l "$zip_path" | tail -n +4 | head -n -2 | awk '{print "   " $4}'
                    echo "----------------------------------------"
                    echo "✅ Valid ZIP file detected"
                    break
                else
                    echo "❌ Not a valid ZIP file"
                    echo "💡 Tip: Make sure you selected a ZIP file"
                    continue
                fi
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