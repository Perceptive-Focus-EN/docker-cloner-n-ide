#!/bin/bash

# Check if a zip file path is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <path_to_zip_file> [container_name]"
    echo "Example: $0 ./myapp.zip my-container"
    exit 1
fi

ZIP_FILE="$1"
CONTAINER_NAME="${2:-loinc-demo-app}"  # Default container name if not provided

# Check if the zip file exists
if [ ! -f "$ZIP_FILE" ]; then
    echo "Error: Zip file '$ZIP_FILE' not found"
    exit 1
fi

# Check if the container exists
if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Error: Container '$CONTAINER_NAME' not found"
    exit 1
fi

# Check if the container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Error: Container '$CONTAINER_NAME' is not running"
    exit 1
fi

# Create a temporary directory for unzipping
TEMP_DIR=$(mktemp -d)
echo "Created temporary directory: $TEMP_DIR"

# Copy the zip file to the container
echo "Copying zip file to container..."
docker cp "$ZIP_FILE" "${CONTAINER_NAME}:/tmp/"

# Get the zip file name
ZIP_FILENAME=$(basename "$ZIP_FILE")

# Execute unzip command in the container
echo "Unzipping file in container..."
docker exec "${CONTAINER_NAME}" sh -c "cd /tmp && unzip -o ${ZIP_FILENAME}"

# Clean up the zip file from the container
echo "Cleaning up..."
docker exec "${CONTAINER_NAME}" sh -c "rm /tmp/${ZIP_FILENAME}"

echo "Done! Files have been unzipped into the container at /tmp" 