FROM ubuntu:22.04

ARG TARGETPLATFORM

# Set non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

# Install common dependencies
RUN apt-get update && apt-get install -y \
    adb \
    sqlite3 \
    python3 \
    python3-pip \
    curl \
    wget \
    unzip \
    git \
    nano \
    vim \
    grep \
    findutils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install iOS tools (if on compatible platform)
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ] || [ "$TARGETPLATFORM" = "linux/arm64" ] || [ -z "$TARGETPLATFORM" ]; then \
    apt-get update && apt-get install -y \
    libimobiledevice-utils \
    ideviceinstaller \
    ifuse \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*; \
    fi

# Skip MVT installation for now to avoid build issues
# We'll install it manually if needed

# Create directory structure
RUN mkdir -p /attack/tools /attack/data /attack/scripts

# Set up working directory
WORKDIR /attack

# Make sure all scripts are executable
RUN find /attack/scripts -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

# Set entrypoint
ENTRYPOINT ["/bin/bash"] 