FROM ubuntu:22.04

ARG TARGETPLATFORM

# Set non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

# Install common dependencies
RUN apt-get update && apt-get install -y \
    adb \
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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*; \
    fi

# Install security monitoring tools
RUN pip3 install --no-cache-dir frida-tools objection

# Create directory structure
RUN mkdir -p /defense/monitor /defense/logs /defense/rules /defense/scripts

# Set up working directory
WORKDIR /defense

# Make sure all scripts are executable
RUN find /defense/scripts -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

# Set entrypoint
ENTRYPOINT ["/bin/bash"] 