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
    echo -e "${GREEN}Languages detected:${NC}"
    
    # Count Python files
    python_count=$(find "$dir" -type f -name "*.py" 2>/dev/null | wc -l)
    python_count=$(echo "$python_count" | tr -d ' ')
    
    # Count JavaScript files
    js_count=$(find "$dir" -type f -name "*.js" 2>/dev/null | wc -l)
    js_count=$(echo "$js_count" | tr -d ' ')
    
    # Count TypeScript files
    ts_count=$(find "$dir" -type f -name "*.ts" 2>/dev/null | wc -l)
    ts_count=$(echo "$ts_count" | tr -d ' ')
    
    # Count HTML files
    html_count=$(find "$dir" -type f -name "*.html" 2>/dev/null | wc -l)
    html_count=$(echo "$html_count" | tr -d ' ')
    
    # Count CSS files
    css_count=$(find "$dir" -type f -name "*.css" 2>/dev/null | wc -l)
    css_count=$(echo "$css_count" | tr -d ' ')
    
    # Count C++ files
    cpp_count=$(find "$dir" -type f -name "*.cpp" 2>/dev/null | wc -l)
    cpp_count=$(echo "$cpp_count" | tr -d ' ')
    
    # Count PHP files
    php_count=$(find "$dir" -type f -name "*.php" 2>/dev/null | wc -l)
    php_count=$(echo "$php_count" | tr -d ' ')
    
    # Count Java files
    java_count=$(find "$dir" -type f -name "*.java" 2>/dev/null | wc -l)
    java_count=$(echo "$java_count" | tr -d ' ')
    
    # Count C# files
    csharp_count=$(find "$dir" -type f -name "*.cs" 2>/dev/null | wc -l)
    csharp_count=$(echo "$csharp_count" | tr -d ' ')
    
    # Count Go files
    go_count=$(find "$dir" -type f -name "*.go" 2>/dev/null | wc -l)
    go_count=$(echo "$go_count" | tr -d ' ')
    
    # Count Rust files
    rust_count=$(find "$dir" -type f -name "*.rs" 2>/dev/null | wc -l)
    rust_count=$(echo "$rust_count" | tr -d ' ')
    
    # Calculate total files
    total_files=$((python_count + js_count + ts_count + html_count + css_count + cpp_count + php_count + java_count + csharp_count + go_count + rust_count))
    
    # Display language counts with percentages
    if [ "$python_count" -gt 0 ]; then
        percentage=$((python_count * 100 / total_files))
        echo -e "  ${YELLOW}Python${NC}: $python_count files ($percentage%)"
    fi
    
    if [ "$js_count" -gt 0 ]; then
        percentage=$((js_count * 100 / total_files))
        echo -e "  ${YELLOW}JavaScript${NC}: $js_count files ($percentage%)"
    fi
    
    if [ "$ts_count" -gt 0 ]; then
        percentage=$((ts_count * 100 / total_files))
        echo -e "  ${YELLOW}TypeScript${NC}: $ts_count files ($percentage%)"
    fi
    
    if [ "$html_count" -gt 0 ]; then
        percentage=$((html_count * 100 / total_files))
        echo -e "  ${YELLOW}HTML${NC}: $html_count files ($percentage%)"
    fi
    
    if [ "$css_count" -gt 0 ]; then
        percentage=$((css_count * 100 / total_files))
        echo -e "  ${YELLOW}CSS${NC}: $css_count files ($percentage%)"
    fi
    
    if [ "$cpp_count" -gt 0 ]; then
        percentage=$((cpp_count * 100 / total_files))
        echo -e "  ${YELLOW}C++${NC}: $cpp_count files ($percentage%)"
    fi
    
    if [ "$php_count" -gt 0 ]; then
        percentage=$((php_count * 100 / total_files))
        echo -e "  ${YELLOW}PHP${NC}: $php_count files ($percentage%)"
    fi
    
    if [ "$java_count" -gt 0 ]; then
        percentage=$((java_count * 100 / total_files))
        echo -e "  ${YELLOW}Java${NC}: $java_count files ($percentage%)"
    fi
    
    if [ "$csharp_count" -gt 0 ]; then
        percentage=$((csharp_count * 100 / total_files))
        echo -e "  ${YELLOW}C#${NC}: $csharp_count files ($percentage%)"
    fi
    
    if [ "$go_count" -gt 0 ]; then
        percentage=$((go_count * 100 / total_files))
        echo -e "  ${YELLOW}Go${NC}: $go_count files ($percentage%)"
    fi
    
    if [ "$rust_count" -gt 0 ]; then
        percentage=$((rust_count * 100 / total_files))
        echo -e "  ${YELLOW}Rust${NC}: $rust_count files ($percentage%)"
    fi
    
    # Detect frameworks
    echo -e "${BLUE}Detecting frameworks...${NC}"
    echo -e "${GREEN}Frameworks detected:${NC}"
    
    # React
    react_count=$(find "$dir" -type f -name "*.jsx" 2>/dev/null | wc -l)
    react_count=$(echo "$react_count" | tr -d ' ')
    if [ "$react_count" -gt 0 ]; then
        echo -e "  ${YELLOW}React${NC} ($react_count matches)"
    fi
    
    # React TypeScript
    reactts_count=$(find "$dir" -type f -name "*.tsx" 2>/dev/null | wc -l)
    reactts_count=$(echo "$reactts_count" | tr -d ' ')
    if [ "$reactts_count" -gt 0 ]; then
        echo -e "  ${YELLOW}React TypeScript${NC} ($reactts_count matches)"
    fi
    
    # Angular
    angular_count=$(find "$dir" -type f -name "*.component.ts" 2>/dev/null | wc -l)
    angular_count=$(echo "$angular_count" | tr -d ' ')
    if [ "$angular_count" -gt 0 ]; then
        echo -e "  ${YELLOW}Angular${NC} ($angular_count matches)"
    fi
    
    # Vue
    vue_count=$(find "$dir" -type f -name "*.vue" 2>/dev/null | wc -l)
    vue_count=$(echo "$vue_count" | tr -d ' ')
    if [ "$vue_count" -gt 0 ]; then
        echo -e "  ${YELLOW}Vue${NC} ($vue_count matches)"
    fi
    
    # FastAPI
    fastapi_count=$(grep -r "from fastapi import" "$dir" 2>/dev/null | wc -l)
    fastapi_count=$(echo "$fastapi_count" | tr -d ' ')
    if [ "$fastapi_count" -gt 0 ]; then
        echo -e "  ${YELLOW}FastAPI${NC} ($fastapi_count matches)"
    fi
    
    # Flask
    flask_count=$(grep -r "from flask import" "$dir" 2>/dev/null | wc -l)
    flask_count=$(echo "$flask_count" | tr -d ' ')
    if [ "$flask_count" -gt 0 ]; then
        echo -e "  ${YELLOW}Flask${NC} ($flask_count matches)"
    fi
    
    # Django
    django_count=$(find "$dir" -name "settings.py" 2>/dev/null | wc -l)
    django_count=$(echo "$django_count" | tr -d ' ')
    if [ "$django_count" -gt 0 ]; then
        echo -e "  ${YELLOW}Django${NC} ($django_count matches)"
    fi
    
    # Express.js
    express_count=$(grep -r "express()" "$dir" 2>/dev/null | wc -l)
    express_count=$(echo "$express_count" | tr -d ' ')
    if [ "$express_count" -gt 0 ]; then
        echo -e "  ${YELLOW}Express.js${NC} ($express_count matches)"
    fi
    
    # NestJS
    nestjs_count=$(grep -r "@Module" "$dir" 2>/dev/null | wc -l)
    nestjs_count=$(echo "$nestjs_count" | tr -d ' ')
    if [ "$nestjs_count" -gt 0 ]; then
        echo -e "  ${YELLOW}NestJS${NC} ($nestjs_count matches)"
    fi
    
    # Detect architecture
    echo -e "${BLUE}Detecting architecture...${NC}"
    echo -e "${GREEN}Architecture patterns detected:${NC}"
    
    # Monorepo
    if [ -d "$dir/packages" ] || [ -d "$dir/apps" ]; then
        echo -e "  ${YELLOW}Monorepo${NC}"
    fi
    
    # Microservices
    if [ -d "$dir/services" ] || [ -d "$dir/microservices" ]; then
        echo -e "  ${YELLOW}Microservices${NC}"
    fi
    
    # Serverless
    serverless_count=$(find "$dir" -name "serverless.yml" 2>/dev/null | wc -l)
    serverless_count=$(echo "$serverless_count" | tr -d ' ')
    if [ "$serverless_count" -gt 0 ]; then
        echo -e "  ${YELLOW}Serverless${NC} ($serverless_count matches)"
    fi
    
    # Azure Functions
    if [ -d "$dir/functions" ] || grep -r "azure-functions" "$dir" 2>/dev/null | grep -q .; then
        echo -e "  ${YELLOW}Azure Functions${NC}"
    fi
    
    # Google Cloud Functions
    if grep -r "functions.https.onCall" "$dir" 2>/dev/null | grep -q .; then
        echo -e "  ${YELLOW}Google Cloud Functions${NC}"
    fi
    
    # Detect cloud provider affinity
    echo -e "${BLUE}Detecting cloud provider affinity...${NC}"
    echo -e "${GREEN}Cloud provider affinity detected:${NC}"
    
    # Azure
    azure_count=0
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
        echo -e "  ${YELLOW}Azure${NC} (confidence: $azure_count)"
    fi
    
    # AWS
    aws_count=0
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
        echo -e "  ${YELLOW}AWS${NC} (confidence: $aws_count)"
    fi
    
    # GCP
    gcp_count=0
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
        echo -e "  ${YELLOW}GCP${NC} (confidence: $gcp_count)"
    fi
    
    # Detect dependency management
    echo -e "${BLUE}Detecting dependency management...${NC}"
    echo -e "${GREEN}Dependency management detected:${NC}"
    
    # Python
    if [ -f "$dir/requirements.txt" ]; then
        echo -e "  ${YELLOW}pip-requirements${NC}"
    fi
    if [ -f "$dir/Pipfile" ]; then
        echo -e "  ${YELLOW}pipenv${NC}"
    fi
    if [ -f "$dir/pyproject.toml" ]; then
        if grep -q "poetry" "$dir/pyproject.toml" 2>/dev/null; then
            echo -e "  ${YELLOW}poetry${NC}"
        elif grep -q "pdm" "$dir/pyproject.toml" 2>/dev/null; then
            echo -e "  ${YELLOW}pdm${NC}"
        else
            echo -e "  ${YELLOW}pyproject${NC}"
        fi
    fi
    if [ -f "$dir/setup.py" ]; then
        echo -e "  ${YELLOW}setuptools${NC}"
    fi
    if [ -f "$dir/environment.yml" ]; then
        echo -e "  ${YELLOW}conda${NC}"
    fi
    
    # JavaScript/TypeScript
    if [ -f "$dir/package.json" ]; then
        if [ -f "$dir/yarn.lock" ]; then
            echo -e "  ${YELLOW}yarn${NC}"
        elif [ -f "$dir/pnpm-lock.yaml" ]; then
            echo -e "  ${YELLOW}pnpm${NC}"
        else
            echo -e "  ${YELLOW}npm${NC}"
        fi
    fi
    
    # Determine primary language
    primary_lang=""
    max_count=0
    
    if [ "$python_count" -gt "$max_count" ]; then
        max_count=$python_count
        primary_lang="Python"
    fi
    
    if [ "$js_count" -gt "$max_count" ]; then
        max_count=$js_count
        primary_lang="JavaScript"
    fi
    
    if [ "$ts_count" -gt "$max_count" ]; then
        max_count=$ts_count
        primary_lang="TypeScript"
    fi
    
    if [ "$java_count" -gt "$max_count" ]; then
        max_count=$java_count
        primary_lang="Java"
    fi
    
    if [ "$csharp_count" -gt "$max_count" ]; then
        max_count=$csharp_count
        primary_lang="C#"
    fi
    
    if [ "$cpp_count" -gt "$max_count" ]; then
        max_count=$cpp_count
        primary_lang="C++"
    fi
    
    if [ "$go_count" -gt "$max_count" ]; then
        max_count=$go_count
        primary_lang="Go"
    fi
    
    if [ "$rust_count" -gt "$max_count" ]; then
        max_count=$rust_count
        primary_lang="Rust"
    fi
    
    # Determine project type
    local project_type=""
    if [ "$primary_lang" = "JavaScript" ] || [ "$primary_lang" = "TypeScript" ]; then
        if [ "$reactts_count" -gt 0 ] || [ "$react_count" -gt 0 ]; then
            project_type="react"
        elif [ "$angular_count" -gt 0 ]; then
            project_type="angular"
        elif [ "$vue_count" -gt 0 ]; then
            project_type="vue"
        elif [ "$express_count" -gt 0 ]; then
            project_type="express"
        elif [ "$nestjs_count" -gt 0 ]; then
            project_type="nestjs"
        else
            project_type="node"
        fi
    elif [ "$primary_lang" = "Python" ]; then
        if [ "$django_count" -gt 0 ]; then
            project_type="django"
        elif [ "$flask_count" -gt 0 ]; then
            project_type="flask"
        elif [ "$fastapi_count" -gt 0 ]; then
            project_type="fastapi"
        elif grep -r "import pandas\|import numpy\|import matplotlib" "$dir" 2>/dev/null | grep -q .; then
            project_type="data-science"
        elif grep -r "import tensorflow\|import torch\|from sklearn" "$dir" 2>/dev/null | grep -q .; then
            project_type="ml-ai"
        else
            project_type="python"
        fi
    elif [ "$primary_lang" = "Java" ]; then
        project_type="java"
    elif [ "$primary_lang" = "C#" ]; then
        project_type="dotnet"
    elif [ "$primary_lang" = "Go" ]; then
        project_type="go"
    elif [ "$primary_lang" = "Rust" ]; then
        project_type="rust"
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