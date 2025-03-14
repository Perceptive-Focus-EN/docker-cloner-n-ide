#!/bin/bash

###########################################
# Project Detector Script
# A robust project type detection system inspired by GitHub Linguist
# This script analyzes a repository to determine:
# 1. Primary language(s)
# 2. Framework(s) in use
# 3. Project structure and architecture
###########################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to count files matching a pattern in a directory
count_files() {
    local dir="$1"
    local pattern="$2"
    local count=0
    
    # Handle multiple patterns separated by spaces
    for p in $pattern; do
        # Use find to count files matching the pattern
        local c=$(find "$dir" -type f -name "$p" 2>/dev/null | wc -l)
        count=$((count + c))
    done
    
    echo "$count"
}

# Function to check for dependencies in package.json
check_npm_deps() {
    local dir="$1"
    local pattern="$2"
    local count=0
    
    # Find all package.json files
    local package_files=$(find "$dir" -name "package.json" 2>/dev/null)
    
    for file in $package_files; do
        # Check if any of the patterns exist in the package.json
        for p in $pattern; do
            if grep -q "\"$p\":" "$file" 2>/dev/null; then
                count=$((count + 1))
            fi
        done
    done
    
    echo "$count"
}

# Function to check for dependencies in Python requirements
check_python_deps() {
    local dir="$1"
    local pattern="$2"
    local count=0
    
    # Find all requirements files
    local req_files=$(find "$dir" -name "requirements.txt" -o -name "Pipfile" -o -name "pyproject.toml" 2>/dev/null)
    
    for file in $req_files; do
        # Check if any of the patterns exist in the requirements file
        for p in $pattern; do
            if grep -q "$p" "$file" 2>/dev/null; then
                count=$((count + 1))
            fi
        done
    done
    
    echo "$count"
}

# Function to check for Java/Maven dependencies
check_java_deps() {
    local dir="$1"
    local pattern="$2"
    local count=0
    
    # Find all pom.xml files
    local pom_files=$(find "$dir" -name "pom.xml" 2>/dev/null)
    
    for file in $pom_files; do
        # Check if any of the patterns exist in the pom.xml
        for p in $pattern; do
            if grep -q "$p" "$file" 2>/dev/null; then
                count=$((count + 1))
            fi
        done
    done
    
    echo "$count"
}

# Function to detect primary languages in a repository
detect_languages() {
    local repo_dir="$1"
    local results=""
    local total_files=0
    
    echo -e "${YELLOW}Analyzing languages in $repo_dir...${NC}"
    
    # Count total files (excluding hidden directories)
    total_files=$(find "$repo_dir" -type f -not -path "*/\.*" | wc -l)
    
    # Check each language
    check_language "javascript" "*.js" "$repo_dir" "$total_files" "$results"
    check_language "typescript" "*.ts *.tsx tsconfig.json" "$repo_dir" "$total_files" "$results"
    check_language "python" "*.py requirements.txt setup.py Pipfile pyproject.toml" "$repo_dir" "$total_files" "$results"
    check_language "java" "*.java pom.xml build.gradle" "$repo_dir" "$total_files" "$results"
    check_language "csharp" "*.cs *.csproj" "$repo_dir" "$total_files" "$results"
    check_language "cpp" "*.cpp *.hpp *.h CMakeLists.txt" "$repo_dir" "$total_files" "$results"
    check_language "go" "*.go go.mod go.sum" "$repo_dir" "$total_files" "$results"
    check_language "rust" "*.rs Cargo.toml" "$repo_dir" "$total_files" "$results"
    check_language "php" "*.php composer.json" "$repo_dir" "$total_files" "$results"
    check_language "ruby" "*.rb Gemfile" "$repo_dir" "$total_files" "$results"
    check_language "swift" "*.swift Package.swift" "$repo_dir" "$total_files" "$results"
    check_language "kotlin" "*.kt build.gradle.kts" "$repo_dir" "$total_files" "$results"
    check_language "scala" "*.scala build.sbt" "$repo_dir" "$total_files" "$results"
    check_language "shell" "*.sh" "$repo_dir" "$total_files" "$results"
    check_language "html" "*.html" "$repo_dir" "$total_files" "$results"
    check_language "css" "*.css" "$repo_dir" "$total_files" "$results"
    check_language "sass" "*.scss *.sass" "$repo_dir" "$total_files" "$results"
    
    # Sort results by count (descending)
    local sorted=$(echo "$results" | sort -t ':' -k2 -nr)
    
    # Print results
    echo -e "${BLUE}Language breakdown:${NC}"
    echo "$sorted" | while IFS=':' read -r lang count percentage; do
        if [ -n "$lang" ]; then
            echo -e "  ${GREEN}$lang${NC}: $count files ($percentage%)"
        fi
    done
    
    # Return primary language (highest count)
    local primary_lang=$(echo "$sorted" | head -n 1 | cut -d ':' -f1)
    if [ -n "$primary_lang" ]; then
        echo "$primary_lang"
    else
        echo "unknown"
    fi
}

# Helper function to check a language and add to results
check_language() {
    local lang="$1"
    local pattern="$2"
    local repo_dir="$3"
    local total_files="$4"
    local results="$5"
    
    local count=$(count_files "$repo_dir" "$pattern")
    
    if [ "$count" -gt 0 ]; then
        local percentage=$((count * 100 / total_files))
        if [ "$percentage" -gt 5 ]; then  # Only include if > 5% of files
            echo "$lang:$count:$percentage"
        fi
    fi
}

# Function to detect frameworks in a repository
detect_frameworks() {
    local repo_dir="$1"
    local primary_lang="$2"
    local results=""
    
    echo -e "${YELLOW}Analyzing frameworks in $repo_dir...${NC}"
    
    # Check each framework
    check_framework "react" "react react-dom" "$repo_dir" "$primary_lang" "$results"
    check_framework "angular" "@angular/core" "$repo_dir" "$primary_lang" "$results"
    check_framework "vue" "vue vue-router" "$repo_dir" "$primary_lang" "$results"
    check_framework "next" "next next-server" "$repo_dir" "$primary_lang" "$results"
    check_framework "nuxt" "nuxt nuxt-edge" "$repo_dir" "$primary_lang" "$results"
    check_framework "express" "express" "$repo_dir" "$primary_lang" "$results"
    check_framework "django" "django" "$repo_dir" "$primary_lang" "$results"
    check_framework "flask" "flask" "$repo_dir" "$primary_lang" "$results"
    check_framework "fastapi" "fastapi" "$repo_dir" "$primary_lang" "$results"
    check_framework "spring" "org.springframework" "$repo_dir" "$primary_lang" "$results"
    check_framework "dotnet" "Microsoft.AspNetCore" "$repo_dir" "$primary_lang" "$results"
    check_framework "laravel" "laravel/framework" "$repo_dir" "$primary_lang" "$results"
    check_framework "rails" "rails" "$repo_dir" "$primary_lang" "$results"
    check_framework "flutter" "flutter" "$repo_dir" "$primary_lang" "$results"
    check_framework "electron" "electron" "$repo_dir" "$primary_lang" "$results"
    check_framework "tensorflow" "tensorflow" "$repo_dir" "$primary_lang" "$results"
    check_framework "pytorch" "torch" "$repo_dir" "$primary_lang" "$results"
    check_framework "azure-sdk" "@azure/ azure-" "$repo_dir" "$primary_lang" "$results"
    check_framework "aws-sdk" "aws-sdk" "$repo_dir" "$primary_lang" "$results"
    check_framework "gcp-sdk" "@google-cloud/" "$repo_dir" "$primary_lang" "$results"
    
    # Sort results by count (descending)
    local sorted=$(echo "$results" | sort -t ':' -k2 -nr)
    
    # Print results
    echo -e "${BLUE}Framework detection:${NC}"
    echo "$sorted" | while IFS=':' read -r framework count; do
        if [ -n "$framework" ]; then
            echo -e "  ${GREEN}$framework${NC}: detected ($count matches)"
        fi
    done
    
    # Return primary framework (highest count)
    local primary_framework=$(echo "$sorted" | head -n 1 | cut -d ':' -f1)
    if [ -n "$primary_framework" ]; then
        echo "$primary_framework"
    else
        echo "none"
    fi
}

# Helper function to check a framework and add to results
check_framework() {
    local framework="$1"
    local pattern="$2"
    local repo_dir="$3"
    local primary_lang="$4"
    local results="$5"
    
    local count=0
    
    # Check based on primary language
    case "$primary_lang" in
        javascript|typescript)
            count=$(check_npm_deps "$repo_dir" "$pattern")
            ;;
        python)
            count=$(check_python_deps "$repo_dir" "$pattern")
            ;;
        java|kotlin|scala)
            count=$(check_java_deps "$repo_dir" "$pattern")
            ;;
        *)
            # For other languages, just check for files
            count=$(count_files "$repo_dir" "$pattern")
            ;;
    esac
    
    if [ "$count" -gt 0 ]; then
        echo "$framework:$count"
    fi
}

# Function to detect project architecture
detect_architecture() {
    local repo_dir="$1"
    local results=""
    
    echo -e "${YELLOW}Analyzing project architecture in $repo_dir...${NC}"
    
    # Check for special directories that indicate project structure
    if [ -d "$repo_dir/frontend" ] && [ -d "$repo_dir/backend" ]; then
        results="$results\nfullstack:10"
    fi
    
    if [ -d "$repo_dir/api" ] && [ -d "$repo_dir/client" ]; then
        results="$results\napi-client:8"
    fi
    
    # Check each architecture pattern
    check_arch "monorepo" "lerna.json nx.json turbo.json pnpm-workspace.yaml" "$repo_dir" "$results"
    check_arch "microservices" "docker-compose.yml kubernetes/ k8s/" "$repo_dir" "$results"
    check_arch "serverless" "serverless.yml netlify.toml vercel.json" "$repo_dir" "$results"
    check_arch "spa" "index.html public/index.html src/index.html" "$repo_dir" "$results"
    check_arch "pwa" "manifest.json service-worker.js" "$repo_dir" "$results"
    check_arch "mobile" "AndroidManifest.xml Info.plist" "$repo_dir" "$results"
    check_arch "desktop" "electron main.js" "$repo_dir" "$results"
    check_arch "library" "package.json setup.py" "$repo_dir" "$results"
    check_arch "api" "swagger.json openapi.yaml" "$repo_dir" "$results"
    check_arch "ml" "model/ models/ train.py" "$repo_dir" "$results"
    check_arch "rag" "embeddings/ vector/ retrieval.py" "$repo_dir" "$results"
    check_arch "azure-functions" "function.json host.json" "$repo_dir" "$results"
    check_arch "azure-webapp" "web.config .deployment" "$repo_dir" "$results"
    
    # Sort results by count (descending)
    local sorted=$(echo -e "$results" | sort -t ':' -k2 -nr)
    
    # Print results
    echo -e "${BLUE}Architecture detection:${NC}"
    echo "$sorted" | while IFS=':' read -r arch count; do
        if [ -n "$arch" ]; then
            echo -e "  ${GREEN}$arch${NC}: detected ($count matches)"
        fi
    done
    
    # Return primary architecture (highest count)
    local primary_arch=$(echo "$sorted" | head -n 1 | cut -d ':' -f1)
    if [ -n "$primary_arch" ]; then
        echo "$primary_arch"
    else
        echo "standard"
    fi
}

# Helper function to check architecture and add to results
check_arch() {
    local arch="$1"
    local pattern="$2"
    local repo_dir="$3"
    local results="$4"
    
    local count=$(count_files "$repo_dir" "$pattern")
    
    if [ "$count" -gt 0 ]; then
        echo "$arch:$count"
    fi
}

# Function to detect cloud provider affinity
detect_cloud_affinity() {
    local repo_dir="$1"
    local results=""
    
    echo -e "${YELLOW}Analyzing cloud provider affinity...${NC}"
    
    # Check for Azure-specific files and patterns
    local azure_count=0
    azure_count=$((azure_count + $(count_files "$repo_dir" "azure*.json azure*.yaml .azure")))
    azure_count=$((azure_count + $(check_npm_deps "$repo_dir" "@azure/ azure-")))
    azure_count=$((azure_count + $(check_python_deps "$repo_dir" "azure-")))
    
    if [ "$azure_count" -gt 0 ]; then
        results="$results\nazure:$azure_count"
    fi
    
    # Check for AWS-specific files and patterns
    local aws_count=0
    aws_count=$((aws_count + $(count_files "$repo_dir" "aws*.json aws*.yaml .aws")))
    aws_count=$((aws_count + $(check_npm_deps "$repo_dir" "aws-sdk")))
    aws_count=$((aws_count + $(check_python_deps "$repo_dir" "boto3 aws-")))
    
    if [ "$aws_count" -gt 0 ]; then
        results="$results\naws:$aws_count"
    fi
    
    # Check for GCP-specific files and patterns
    local gcp_count=0
    gcp_count=$((gcp_count + $(count_files "$repo_dir" "gcp*.json gcp*.yaml .gcp app.yaml")))
    gcp_count=$((gcp_count + $(check_npm_deps "$repo_dir" "@google-cloud/")))
    gcp_count=$((gcp_count + $(check_python_deps "$repo_dir" "google-cloud-")))
    
    if [ "$gcp_count" -gt 0 ]; then
        results="$results\ngcp:$gcp_count"
    fi
    
    # Sort results by count (descending)
    local sorted=$(echo -e "$results" | sort -t ':' -k2 -nr)
    
    # Print results
    echo -e "${BLUE}Cloud provider affinity:${NC}"
    echo "$sorted" | while IFS=':' read -r provider count; do
        if [ -n "$provider" ]; then
            echo -e "  ${GREEN}$provider${NC}: detected ($count matches)"
        fi
    done
    
    # Return primary cloud provider (highest count)
    local primary_provider=$(echo "$sorted" | head -n 1 | cut -d ':' -f1)
    if [ -n "$primary_provider" ]; then
        echo "$primary_provider"
    else
        echo "none"
    fi
}

# Main function to analyze a repository
analyze_repository() {
    local repo_dir="$1"
    
    if [ ! -d "$repo_dir" ]; then
        echo -e "${RED}Error: Directory $repo_dir does not exist${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}=== Project Analysis for $repo_dir ===${NC}"
    
    # Detect primary language
    local primary_lang=$(detect_languages "$repo_dir")
    
    # Detect frameworks
    local primary_framework=$(detect_frameworks "$repo_dir" "$primary_lang")
    
    # Detect architecture
    local primary_arch=$(detect_architecture "$repo_dir")
    
    # Detect cloud provider affinity
    local primary_cloud=$(detect_cloud_affinity "$repo_dir")
    
    # Determine project type based on all detections
    local project_type=""
    
    # First check for specialized project types
    if [[ "$primary_arch" == "fullstack" || "$primary_arch" == "api-client" ]]; then
        if [[ "$primary_framework" == "react" || "$primary_framework" == "angular" || "$primary_framework" == "vue" ]]; then
            if [[ "$primary_cloud" == "azure" ]]; then
                project_type="azure-fullstack"
            else
                project_type="fullstack-$primary_framework"
            fi
        elif [[ "$primary_lang" == "typescript" || "$primary_lang" == "javascript" ]]; then
            project_type="js-fullstack"
        else
            project_type="$primary_lang-fullstack"
        fi
    elif [[ "$primary_arch" == "rag" ]]; then
        if [[ "$primary_cloud" == "azure" ]]; then
            project_type="azure-rag"
        else
            project_type="$primary_lang-rag"
        fi
    else
        # Default to language-framework combination
        if [[ "$primary_framework" != "none" ]]; then
            project_type="$primary_lang-$primary_framework"
        else
            project_type="$primary_lang"
        fi
    fi
    
    # Special case for Azure React projects
    if [[ "$primary_framework" == "react" && "$primary_cloud" == "azure" ]]; then
        project_type="azure-react"
    fi
    
    echo -e "\n${BLUE}=== Project Analysis Summary ===${NC}"
    echo -e "Primary Language: ${GREEN}$primary_lang${NC}"
    echo -e "Primary Framework: ${GREEN}$primary_framework${NC}"
    echo -e "Architecture: ${GREEN}$primary_arch${NC}"
    echo -e "Cloud Affinity: ${GREEN}$primary_cloud${NC}"
    echo -e "Project Type: ${GREEN}$project_type${NC}"
    
    # Return the project type
    echo "$project_type"
}

# If script is run directly, analyze the specified directory
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ $# -eq 0 ]; then
        echo -e "${RED}Error: Please provide a repository directory${NC}"
        echo -e "Usage: $0 <repository_directory>"
        exit 1
    fi
    
    analyze_repository "$1"
fi

# Export the main function
export -f analyze_repository 