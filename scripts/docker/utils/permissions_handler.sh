#!/bin/bash

###########################################
# Docker Permissions Handler Utility
# Standalone utility for managing Docker container permissions
# No dependencies on other scripts
#
# Provides:
# - fix_docker_permissions()
# - check_and_fix_permissions()
###########################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to fix Docker file permissions
fix_docker_permissions() {
    local container_name="$1"
    local target_path="$2"
    local user_id=${3:-$(id -u)}
    local group_id=${4:-$(id -g)}

    echo -e "${YELLOW}🔧 Fixing permissions in container ${container_name}...${NC}"

    # Create a temporary script to fix permissions
    cat > /tmp/fix_perms.sh << 'EOF'
#!/bin/bash
target_path="$1"
user_id="$2"
group_id="$3"

# Ensure target directory exists
mkdir -p "$target_path"

# Reset permissions
chown -R root:root "$target_path"
chmod -R 755 "$target_path"

# Create user if doesn't exist
if ! getent passwd $user_id >/dev/null; then
    adduser --uid $user_id --disabled-password --gecos "" dockeruser
fi

# Set group if doesn't exist
if ! getent group $group_id >/dev/null; then
    groupadd -g $group_id dockergroup
fi

# Apply permissions
chown -R $user_id:$group_id "$target_path"
EOF

    # Copy the script to container
    if ! docker cp /tmp/fix_perms.sh "$container_name:/tmp/fix_perms.sh"; then
        echo -e "${RED}❌ Failed to copy permission fix script${NC}"
        rm -f /tmp/fix_perms.sh
        return 1
    fi

    # Make script executable and run it
    if ! docker exec "$container_name" bash -c "chmod +x /tmp/fix_perms.sh && /tmp/fix_perms.sh '$target_path' $user_id $group_id"; then
        echo -e "${RED}❌ Failed to fix permissions${NC}"
        rm -f /tmp/fix_perms.sh
        return 1
    fi

    # Cleanup
    rm -f /tmp/fix_perms.sh
    docker exec "$container_name" rm -f /tmp/fix_perms.sh

    echo -e "${GREEN}✅ Permissions fixed successfully${NC}"
    return 0
}

# Function to check and fix container permissions
check_and_fix_permissions() {
    local container_name="$1"
    local target_path="$2"

    echo -e "${YELLOW}🔍 Checking container permissions...${NC}"

    # Try to write to target path
    if ! docker exec "$container_name" bash -c "touch '$target_path/.permissions_test' 2>/dev/null"; then
        echo -e "${YELLOW}⚠️ Permission issues detected${NC}"
        fix_docker_permissions "$container_name" "$target_path"
        return $?
    fi

    # Cleanup test file
    docker exec "$container_name" rm -f "$target_path/.permissions_test"
    echo -e "${GREEN}✅ Permissions look good${NC}"
    return 0
}

# Export functions
export -f fix_docker_permissions
export -f check_and_fix_permissions 