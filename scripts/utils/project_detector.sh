#!/bin/bash

# Project Detector
# This script analyzes a repository to determine:
# 1. Primary languages in use
# 2. Frameworks in use
# 3. Project architecture
# 4. Cloud provider affinity
# Based on GitHub Linguist approach with additional heuristics

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to count files matching a pattern
count_files() {
    local dir="$1"
    local pattern="$2"
    find "$dir" -type f -name "$pattern" 2>/dev/null | wc -l
}

# Function to check if a language is present
check_language() {
    local dir="$1"
    local lang="$2"
    local pattern="$3"
    local count=$(count_files "$dir" "$pattern")
    if [ "$count" -gt 0 ]; then
        echo "$lang:$count"
    fi
}

# Function to check if a framework is present
check_framework() {
    local dir="$1"
    local framework="$2"
    local pattern="$3"
    local count=$(count_files "$dir" "$pattern")
    if [ "$count" -gt 0 ]; then
        echo "$framework:$count"
    fi
}

# Function to check if an architecture pattern is present
check_arch() {
    local dir="$1"
    local arch="$2"
    local pattern="$3"
    local count=$(count_files "$dir" "$pattern")
    if [ "$count" -gt 0 ]; then
        echo "$arch:$count"
    fi
}

# Function to check dependencies in package.json
check_npm_deps() {
    local dir="$1"
    local package_file="$dir/package.json"
    local deps=""
    
    if [ -f "$package_file" ]; then
        # Check for React
        if grep -q '"react"' "$package_file"; then
            deps="$deps react"
        fi
        # Check for Angular
        if grep -q '"@angular/core"' "$package_file"; then
            deps="$deps angular"
        fi
        # Check for Vue
        if grep -q '"vue"' "$package_file"; then
            deps="$deps vue"
        fi
        # Check for Next.js
        if grep -q '"next"' "$package_file"; then
            deps="$deps nextjs"
        fi
        # Check for Express
        if grep -q '"express"' "$package_file"; then
            deps="$deps express"
        fi
        # Check for NestJS
        if grep -q '"@nestjs/core"' "$package_file"; then
            deps="$deps nestjs"
        fi
    fi
    echo "$deps"
}

# Function to check Python dependencies
check_python_deps() {
    local dir="$1"
    local deps=""
    
    # Check requirements.txt
    if [ -f "$dir/requirements.txt" ]; then
        # Check for Django
        if grep -q "django" "$dir/requirements.txt"; then
            deps="$deps django"
        fi
        # Check for Flask
        if grep -q "flask" "$dir/requirements.txt"; then
            deps="$deps flask"
        fi
        # Check for FastAPI
        if grep -q "fastapi" "$dir/requirements.txt"; then
            deps="$deps fastapi"
        fi
        # Check for Pandas
        if grep -q "pandas" "$dir/requirements.txt"; then
            deps="$deps pandas"
        fi
        # Check for TensorFlow
        if grep -q "tensorflow" "$dir/requirements.txt"; then
            deps="$deps tensorflow"
        fi
        # Check for PyTorch
        if grep -q "torch" "$dir/requirements.txt"; then
            deps="$deps pytorch"
        fi
    fi
    
    # Check pyproject.toml
    if [ -f "$dir/pyproject.toml" ]; then
        # Check for Django
        if grep -q "django" "$dir/pyproject.toml"; then
            deps="$deps django"
        fi
        # Check for Flask
        if grep -q "flask" "$dir/pyproject.toml"; then
            deps="$deps flask"
        fi
        # Check for FastAPI
        if grep -q "fastapi" "$dir/pyproject.toml"; then
            deps="$deps fastapi"
        fi
        # Check for Pandas
        if grep -q "pandas" "$dir/pyproject.toml"; then
            deps="$deps pandas"
        fi
        # Check for TensorFlow
        if grep -q "tensorflow" "$dir/pyproject.toml"; then
            deps="$deps tensorflow"
        fi
        # Check for PyTorch
        if grep -q "torch" "$dir/pyproject.toml"; then
            deps="$deps pytorch"
        fi
    fi
    
    # Check setup.py
    if [ -f "$dir/setup.py" ]; then
        # Check for Django
        if grep -q "django" "$dir/setup.py"; then
            deps="$deps django"
        fi
        # Check for Flask
        if grep -q "flask" "$dir/setup.py"; then
            deps="$deps flask"
        fi
        # Check for FastAPI
        if grep -q "fastapi" "$dir/setup.py"; then
            deps="$deps fastapi"
        fi
        # Check for Pandas
        if grep -q "pandas" "$dir/setup.py"; then
            deps="$deps pandas"
        fi
        # Check for TensorFlow
        if grep -q "tensorflow" "$dir/setup.py"; then
            deps="$deps tensorflow"
        fi
        # Check for PyTorch
        if grep -q "torch" "$dir/setup.py"; then
            deps="$deps pytorch"
        fi
    fi
    
    echo "$deps"
}

# Function to detect languages in the repository
detect_languages() {
    local dir="$1"
    local results=""
    
    # JavaScript
    local js_count=$(count_files "$dir" "*.js")
    if [ "$js_count" -gt 0 ]; then
        results="$results JavaScript:$js_count"
    fi
    
    # TypeScript
    local ts_count=$(count_files "$dir" "*.ts")
    if [ "$ts_count" -gt 0 ]; then
        results="$results TypeScript:$ts_count"
    fi
    
    # Python
    local py_count=$(count_files "$dir" "*.py")
    if [ "$py_count" -gt 0 ]; then
        results="$results Python:$py_count"
    fi
    
    # Java
    local java_count=$(count_files "$dir" "*.java")
    if [ "$java_count" -gt 0 ]; then
        results="$results Java:$java_count"
    fi
    
    # C#
    local csharp_count=$(count_files "$dir" "*.cs")
    if [ "$csharp_count" -gt 0 ]; then
        results="$results C#:$csharp_count"
    fi
    
    # C++
    local cpp_count=$(count_files "$dir" "*.cpp")
    if [ "$cpp_count" -gt 0 ]; then
        results="$results C++:$cpp_count"
    fi
    
    # Go
    local go_count=$(count_files "$dir" "*.go")
    if [ "$go_count" -gt 0 ]; then
        results="$results Go:$go_count"
    fi
    
    # Rust
    local rust_count=$(count_files "$dir" "*.rs")
    if [ "$rust_count" -gt 0 ]; then
        results="$results Rust:$rust_count"
    fi
    
    # Ruby
    local ruby_count=$(count_files "$dir" "*.rb")
    if [ "$ruby_count" -gt 0 ]; then
        results="$results Ruby:$ruby_count"
    fi
    
    # PHP
    local php_count=$(count_files "$dir" "*.php")
    if [ "$php_count" -gt 0 ]; then
        results="$results PHP:$php_count"
    fi
    
    # HTML
    local html_count=$(count_files "$dir" "*.html")
    if [ "$html_count" -gt 0 ]; then
        results="$results HTML:$html_count"
    fi
    
    # CSS
    local css_count=$(count_files "$dir" "*.css")
    if [ "$css_count" -gt 0 ]; then
        results="$results CSS:$css_count"
    fi
    
    echo "$results"
}

# Function to detect frameworks in the repository
detect_frameworks() {
    local dir="$1"
    local results=""
    
    # React
    local react_count=$(count_files "$dir" "*.jsx")
    if [ "$react_count" -gt 0 ]; then
        results="$results React:$react_count"
    fi
    
    # React with TypeScript
    local reactts_count=$(count_files "$dir" "*.tsx")
    if [ "$reactts_count" -gt 0 ]; then
        results="$results ReactTS:$reactts_count"
    fi
    
    # Angular
    local angular_count=$(count_files "$dir" "*.component.ts")
    if [ "$angular_count" -gt 0 ]; then
        results="$results Angular:$angular_count"
    fi
    
    # Vue
    local vue_count=$(count_files "$dir" "*.vue")
    if [ "$vue_count" -gt 0 ]; then
        results="$results Vue:$vue_count"
    fi
    
    # Django
    local django_count=$(count_files "$dir" "*/settings.py")
    if [ "$django_count" -gt 0 ]; then
        results="$results Django:$django_count"
    fi
    
    # Flask
    local flask_count=$(count_files "$dir" "*app.py")
    if [ "$flask_count" -gt 0 ]; then
        results="$results Flask:$flask_count"
    fi
    
    # FastAPI
    local fastapi_count=$(count_files "$dir" "*main.py")
    if [ "$fastapi_count" -eq 0 ]; then
        # Also check for FastAPI imports
        if grep -r "from fastapi import" "$dir" 2>/dev/null | grep -q .; then
            results="$results FastAPI:1"
        fi
    else
        results="$results FastAPI:$fastapi_count"
    fi
    
    # Spring Boot
    local springboot_count=$(count_files "$dir" "*Application.java")
    if [ "$springboot_count" -gt 0 ]; then
        results="$results SpringBoot:$springboot_count"
    fi
    
    # Express.js
    if grep -r "express()" "$dir" 2>/dev/null | grep -q .; then
        results="$results Express:1"
    fi
    
    # NestJS
    if grep -r "@Module" "$dir" 2>/dev/null | grep -q .; then
        results="$results NestJS:1"
    fi
    
    # Check package.json for JS frameworks
    local npm_deps=$(check_npm_deps "$dir")
    if [ ! -z "$npm_deps" ]; then
        for dep in $npm_deps; do
            results="$results $dep:1"
        done
    fi
    
    # Check Python dependencies
    local python_deps=$(check_python_deps "$dir")
    if [ ! -z "$python_deps" ]; then
        for dep in $python_deps; do
            results="$results $dep:1"
        done
    fi
    
    echo "$results"
}

# Function to detect architecture patterns
detect_architecture() {
    local dir="$1"
    local results=""
    
    # Monorepo
    if [ -d "$dir/packages" ] || [ -d "$dir/apps" ]; then
        results="$results Monorepo:1"
    fi
    
    # Microservices
    if [ -d "$dir/services" ] || [ -d "$dir/microservices" ]; then
        results="$results Microservices:1"
    fi
    
    # Serverless
    local serverless=$(check_arch "$dir" "Serverless" "serverless.yml")
    if [ ! -z "$serverless" ]; then
        results="$results $serverless"
    fi
    
    # Check for AWS SAM
    local sam=$(check_arch "$dir" "Serverless" "template.yaml")
    if [ ! -z "$sam" ]; then
        results="$results $sam"
    fi
    
    # Check for Azure Functions
    if [ -d "$dir/functions" ] || grep -r "azure-functions" "$dir" 2>/dev/null | grep -q .; then
        results="$results AzureFunctions:1"
    fi
    
    # Check for Google Cloud Functions
    if grep -r "functions.https.onCall" "$dir" 2>/dev/null | grep -q .; then
        results="$results GCPFunctions:1"
    fi
    
    echo "$results"
}

# Function to detect cloud provider affinity
detect_cloud_affinity() {
    local dir="$1"
    local results=""
    
    # Azure
    local azure_count=0
    if grep -r "azure" "$dir" 2>/dev/null | grep -q .; then
        azure_count=$((azure_count + 1))
    fi
    if grep -r "Microsoft.Azure" "$dir" 2>/dev/null | grep -q .; then
        azure_count=$((azure_count + 1))
    fi
    if [ -f "$dir/azure-pipelines.yml" ]; then
        azure_count=$((azure_count + 1))
    fi
    if [ "$azure_count" -gt 0 ]; then
        results="$results Azure:$azure_count"
    fi
    
    # AWS
    local aws_count=0
    if grep -r "aws-sdk" "$dir" 2>/dev/null | grep -q .; then
        aws_count=$((aws_count + 1))
    fi
    if grep -r "amazonaws" "$dir" 2>/dev/null | grep -q .; then
        aws_count=$((aws_count + 1))
    fi
    if [ -f "$dir/cloudformation.yml" ] || [ -f "$dir/cloudformation.yaml" ]; then
        aws_count=$((aws_count + 1))
    fi
    if [ "$aws_count" -gt 0 ]; then
        results="$results AWS:$aws_count"
    fi
    
    # GCP
    local gcp_count=0
    if grep -r "google-cloud" "$dir" 2>/dev/null | grep -q .; then
        gcp_count=$((gcp_count + 1))
    fi
    if grep -r "gcloud" "$dir" 2>/dev/null | grep -q .; then
        gcp_count=$((gcp_count + 1))
    fi
    if [ -f "$dir/app.yaml" ]; then
        gcp_count=$((gcp_count + 1))
    fi
    if [ "$gcp_count" -gt 0 ]; then
        results="$results GCP:$gcp_count"
    fi
    
    echo "$results"
}

# Function to detect Python project type in more detail
detect_python_project_type() {
    local dir="$1"
    local results=""
    
    # Check for Django
    if [ -f "$dir/manage.py" ] && grep -q "django" "$dir/manage.py" 2>/dev/null; then
        results="django"
    # Check for Flask
    elif grep -r "from flask import" "$dir" 2>/dev/null | grep -q .; then
        results="flask"
    # Check for FastAPI
    elif grep -r "from fastapi import" "$dir" 2>/dev/null | grep -q .; then
        results="fastapi"
    # Check for Data Science
    elif grep -r "import pandas" "$dir" 2>/dev/null | grep -q . || \
         grep -r "import numpy" "$dir" 2>/dev/null | grep -q . || \
         grep -r "import matplotlib" "$dir" 2>/dev/null | grep -q .; then
        results="data-science"
    # Check for ML/AI
    elif grep -r "import tensorflow" "$dir" 2>/dev/null | grep -q . || \
         grep -r "import torch" "$dir" 2>/dev/null | grep -q . || \
         grep -r "from sklearn" "$dir" 2>/dev/null | grep -q .; then
        results="ml-ai"
    # Check for CLI tool
    elif [ -f "$dir/setup.py" ] && grep -q "console_scripts" "$dir/setup.py" 2>/dev/null; then
        results="cli-tool"
    # Check for API
    elif grep -r "def get" "$dir" 2>/dev/null | grep -q . && \
         grep -r "def post" "$dir" 2>/dev/null | grep -q .; then
        results="api"
    # Default to generic
    else
        results="generic"
    fi
    
    echo "$results"
}

# Function to detect dependency management approach
detect_dependency_management() {
    local dir="$1"
    local results=""
    
    # Python
    if [ -f "$dir/requirements.txt" ]; then
        results="$results pip-requirements"
    fi
    if [ -f "$dir/Pipfile" ]; then
        results="$results pipenv"
    fi
    if [ -f "$dir/pyproject.toml" ]; then
        if grep -q "poetry" "$dir/pyproject.toml" 2>/dev/null; then
            results="$results poetry"
        elif grep -q "pdm" "$dir/pyproject.toml" 2>/dev/null; then
            results="$results pdm"
        else
            results="$results pyproject"
        fi
    fi
    if [ -f "$dir/setup.py" ]; then
        results="$results setuptools"
    fi
    if [ -f "$dir/environment.yml" ]; then
        results="$results conda"
    fi
    
    # JavaScript/TypeScript
    if [ -f "$dir/package.json" ]; then
        if [ -f "$dir/yarn.lock" ]; then
            results="$results yarn"
        elif [ -f "$dir/pnpm-lock.yaml" ]; then
            results="$results pnpm"
        else
            results="$results npm"
        fi
    fi
    
    # Java
    if [ -f "$dir/pom.xml" ]; then
        results="$results maven"
    fi
    if [ -f "$dir/build.gradle" ]; then
        results="$results gradle"
    fi
    
    # .NET
    if [ -f "$dir/*.csproj" ] || [ -f "$dir/*.sln" ]; then
        results="$results nuget"
    fi
    
    # Go
    if [ -f "$dir/go.mod" ]; then
        results="$results go-modules"
    fi
    
    # Rust
    if [ -f "$dir/Cargo.toml" ]; then
        results="$results cargo"
    fi
    
    echo "$results"
}

# Main function to analyze a repository
analyze_repository() {
    local dir="$1"
    
    if [ ! -d "$dir" ]; then
        echo -e "${RED}Directory $dir does not exist${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Analyzing project at ${YELLOW}$dir${NC}"
    
    # Detect languages
    echo -e "${BLUE}Detecting languages...${NC}"
    local languages=$(detect_languages "$dir")
    
    # Calculate total files
    local total_files=0
    for lang_count in $languages; do
        local count=$(echo "$lang_count" | cut -d':' -f2)
        if [[ "$count" =~ ^[0-9]+$ ]]; then
            total_files=$((total_files + count))
        fi
    done
    
    # Display languages with percentages
    if [ ! -z "$languages" ]; then
        echo -e "${GREEN}Languages detected:${NC}"
        for lang_count in $languages; do
            local lang=$(echo "$lang_count" | cut -d':' -f1)
            local count=$(echo "$lang_count" | cut -d':' -f2)
            local percentage=0
            if [ "$total_files" -gt 0 ] && [[ "$count" =~ ^[0-9]+$ ]]; then
                percentage=$(( (count * 100) / total_files ))
            fi
            echo -e "  ${YELLOW}$lang${NC}: $count files ($percentage%)"
        done
    else
        echo -e "${YELLOW}No languages detected${NC}"
    fi
    
    # Detect frameworks
    echo -e "${BLUE}Detecting frameworks...${NC}"
    local frameworks=$(detect_frameworks "$dir")
    if [ ! -z "$frameworks" ]; then
        echo -e "${GREEN}Frameworks detected:${NC}"
        for framework_count in $frameworks; do
            local framework=$(echo "$framework_count" | cut -d':' -f1)
            local count=$(echo "$framework_count" | cut -d':' -f2)
            if [[ "$count" =~ ^[0-9]+$ ]]; then
                echo -e "  ${YELLOW}$framework${NC} ($count matches)"
            fi
        done
    else
        echo -e "${YELLOW}No frameworks detected${NC}"
    fi
    
    # Detect architecture
    echo -e "${BLUE}Detecting architecture...${NC}"
    local architecture=$(detect_architecture "$dir")
    if [ ! -z "$architecture" ]; then
        echo -e "${GREEN}Architecture patterns detected:${NC}"
        for arch_count in $architecture; do
            local arch=$(echo "$arch_count" | cut -d':' -f1)
            echo -e "  ${YELLOW}$arch${NC}"
        done
    else
        echo -e "${YELLOW}No specific architecture pattern detected${NC}"
    fi
    
    # Detect cloud affinity
    echo -e "${BLUE}Detecting cloud provider affinity...${NC}"
    local cloud=$(detect_cloud_affinity "$dir")
    if [ ! -z "$cloud" ]; then
        echo -e "${GREEN}Cloud provider affinity detected:${NC}"
        for cloud_count in $cloud; do
            local provider=$(echo "$cloud_count" | cut -d':' -f1)
            local count=$(echo "$cloud_count" | cut -d':' -f2)
            echo -e "  ${YELLOW}$provider${NC} (confidence: $count)"
        done
    else
        echo -e "${YELLOW}No specific cloud provider affinity detected${NC}"
    fi
    
    # Detect dependency management
    echo -e "${BLUE}Detecting dependency management...${NC}"
    local dep_mgmt=$(detect_dependency_management "$dir")
    if [ ! -z "$dep_mgmt" ]; then
        echo -e "${GREEN}Dependency management detected:${NC}"
        for dm in $dep_mgmt; do
            echo -e "  ${YELLOW}$dm${NC}"
        done
    else
        echo -e "${YELLOW}No specific dependency management detected${NC}"
    fi
    
    # Determine primary language
    local primary_lang=""
    local max_count=0
    for lang_count in $languages; do
        local lang=$(echo "$lang_count" | cut -d':' -f1)
        local count=$(echo "$lang_count" | cut -d':' -f2)
        if [[ "$count" =~ ^[0-9]+$ ]] && [ "$count" -gt "$max_count" ]; then
            max_count=$count
            primary_lang=$lang
        fi
    done
    
    # Determine project type
    local project_type=""
    if [ "$primary_lang" = "JavaScript" ] || [ "$primary_lang" = "TypeScript" ]; then
        if echo "$frameworks" | grep -q "React"; then
            project_type="react"
        elif echo "$frameworks" | grep -q "Angular"; then
            project_type="angular"
        elif echo "$frameworks" | grep -q "Vue"; then
            project_type="vue"
        elif echo "$frameworks" | grep -q "Express"; then
            project_type="express"
        elif echo "$frameworks" | grep -q "NestJS"; then
            project_type="nestjs"
        elif echo "$frameworks" | grep -q "NextJS"; then
            project_type="nextjs"
        else
            project_type="node"
        fi
    elif [ "$primary_lang" = "Python" ]; then
        project_type=$(detect_python_project_type "$dir")
    elif [ "$primary_lang" = "Java" ]; then
        if echo "$frameworks" | grep -q "SpringBoot"; then
            project_type="spring-boot"
        else
            project_type="java"
        fi
    elif [ "$primary_lang" = "C#" ]; then
        project_type="dotnet"
    elif [ "$primary_lang" = "Go" ]; then
        project_type="go"
    elif [ "$primary_lang" = "Rust" ]; then
        project_type="rust"
    elif [ "$primary_lang" = "Ruby" ]; then
        if [ -f "$dir/config/routes.rb" ]; then
            project_type="rails"
        else
            project_type="ruby"
        fi
    elif [ "$primary_lang" = "PHP" ]; then
        if [ -f "$dir/artisan" ]; then
            project_type="laravel"
        else
            project_type="php"
        fi
    else
        project_type="unknown"
    fi
    
    echo -e "${PURPLE}Project Summary:${NC}"
    echo -e "  ${CYAN}Primary Language:${NC} ${YELLOW}$primary_lang${NC}"
    echo -e "  ${CYAN}Project Type:${NC} ${YELLOW}$project_type${NC}"
    
    # Return the project type for use by other scripts
    echo "$project_type"
}

# Export the main function
export -f analyze_repository

# If script is run directly, analyze the specified directory
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ $# -eq 0 ]; then
        echo -e "${RED}Error: Please provide a repository directory${NC}"
        echo -e "Usage: $0 <repository_directory>"
        exit 1
    fi
    
    analyze_repository "$1"
fi