# Multi-Platform Mobile Security Testing Environment

This guide helps you set up a cross-platform mobile security testing environment using Docker containers. The environment works with both Android and iOS devices and supports multiple processor architectures (x86/AMD64 and ARM).

## Project Structure

```
mobile-security-lab/
├── attacker/
│   ├── Dockerfile
│   ├── tools/
│   ├── data/
│   └── scripts/
├── defender/
│   ├── Dockerfile
│   ├── monitor/
│   ├── logs/
│   ├── rules/
│   └── scripts/
├── shared/
└── docker-compose.yml
```

## Platform Compatibility

This setup supports:
- **Processor architectures**: AMD64/x86_64, ARM64 (for M1/M2 Macs and other ARM systems)
- **Mobile platforms**: Both Android and iOS devices
- **Host systems**: Linux, macOS, and Windows with Docker installed

## Setup Steps

### 1. Prepare Your Environment

First, make sure Docker and Docker Compose are installed on your system.

For macOS/Linux:
```bash
# Check Docker installation
docker --version
docker-compose --version
```

For Windows, ensure Docker Desktop is installed and running.

### 2. Prepare the Directory Structure

```bash
mkdir -p mobile-security-lab/attacker/{tools,data,scripts}
mkdir -p mobile-security-lab/defender/{monitor,logs,rules,scripts}
mkdir -p mobile-security-lab/shared
cd mobile-security-lab
```

### 3. Create Dockerfiles and Docker Compose File

1. Save the Attacker Dockerfile to `attacker/Dockerfile`
2. Save the Defender Dockerfile to `defender/Dockerfile`
3. Save the Docker Compose file to `docker-compose.yml`

The Dockerfiles already contain the built-in scripts needed for testing.

### 4. Build and Start the Environment

```bash
# Start the basic environment (without emulator)
docker-compose up -d

# If you want to include the Android emulator (AMD64/x86_64 only)
docker-compose --profile emulator up -d
```

Note: The Android emulator only works on x86_64/AMD64 systems, not on ARM-based systems like M1/M2 Macs.

### 5. Verify the Setup

```bash
# Check if containers are running
docker-compose ps

# You should see the attacker and defender containers running
```

## Working with Physical Devices

### Android Devices

1. Enable USB debugging on your Android device:
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times to enable Developer Options
   - Go to Settings → Developer Options → Enable USB Debugging
   - Connect your device to the computer

2. Check the connection from the attacker container:
```bash
docker exec -it mobile-attacker adb devices
```

You should see your device listed.

### iOS Devices (on Linux/macOS hosts)

1. On your iOS device:
   - No special preparation needed for basic testing
   - For advanced testing, you may need to jailbreak

2. Check connection (if libimobiledevice tools are available):
```bash
docker exec -it mobile-attacker idevice_id -l
```

## Running Attack Simulations

Access the attacker container:

```bash
docker exec -it mobile-attacker bash
```

### Automatic Device Detection and Extraction

The environment now includes scripts that automatically detect connected devices and run the appropriate extraction tools:

```bash
# Run the automatic extraction workflow (detects device type and runs appropriate tools)
/attack/scripts/extract-all.sh

# Verify that all necessary tools are installed
/attack/scripts/common/verify-tools.sh

# If tools are missing, install them
/attack/scripts/common/install-tools.sh
```

### For Android Devices

```bash
# Run pre-made extraction script
/attack/scripts/android/extract-messages.sh

# Or use MVT directly
mvt-android check-adb -o /attack/data/mvt-results
```

### For iOS Devices (if supported on your host platform)

```bash
# Run pre-made iOS extraction script
/attack/scripts/ios/extract-ios.sh
```

### Using KeyDroid (a more reliable keylogger than the original source)

```bash
cd /attack/tools/keydroid
# Review the tools and procedures
cat README.md
```

## Monitoring Defenses

Access the defender container:

```bash
docker exec -it mobile-defender bash
```

### Start Multi-Platform Monitoring

```bash
# This will automatically detect connected devices and start appropriate monitoring
/defense/scripts/common/monitor-all.sh
```

### Monitor Specific Platform

```bash
# For Android
/defense/scripts/android/monitor-android.sh

# For iOS (if available)
/defense/scripts/ios/monitor-ios.sh
```

### Check the Logs

```bash
# View today's logs
ls -la /defense/logs/$(date +%Y-%m-%d)/
```

## Analyzing Results

Both containers share a volume mounted at `/shared`, which you can use to exchange data:

```bash
# From the attacker container, save extraction results
cp -r /attack/data/extraction /shared/

# From the defender container, analyze those results
ls -la /shared/extraction/
```

## Building Custom Security Apps

The defender container has the tools needed to build security apps:

```bash
cd /defense/secure-apps
# Create custom app using Android or iOS tools
```

## Working with Multiple Device Types

The scripts automatically detect device types. To monitor both Android and iOS devices simultaneously, simply:

1. Connect both types of devices to your host computer
2. Run the multi-platform monitoring script:
```bash
/defense/scripts/common/monitor-all.sh
```

## Using the Android Emulator (x86_64/AMD64 systems only)

If you started the environment with the emulator profile, access it via:

```bash
# Get the noVNC URL
echo "http://localhost:6080"
```

Open this URL in your browser to access the emulated Android device.

## Troubleshooting

### USB Device Access

If devices aren't detected, ensure your user has permissions to access USB devices:

```bash
# On Linux, add your user to the plugdev group
sudo usermod -aG plugdev $USER
sudo bash -c 'echo "SUBSYSTEM==\"usb\", MODE=\"0666\"" > /etc/udev/rules.d/51-android.rules'
sudo udevadm control --reload-rules
```

### Missing Tools

If extraction tools are missing:

```bash
# Inside the attacker container
/attack/scripts/common/verify-tools.sh  # Check what tools are missing
/attack/scripts/common/install-tools.sh # Install missing tools
```

### Container Issues

If a container fails to start:

```bash
# Check logs
docker-compose logs attacker
docker-compose logs defender

# Rebuild containers
docker-compose build --no-cache
```

## Cleaning Up

When finished, shut down the environment:

```bash
# Stop all containers
docker-compose down

# If you used the emulator
docker-compose --profile emulator down
```

## Advanced Setup

For deeper analysis, you can add more specific tools to each container by modifying the Dockerfiles and rebuilding:

```bash
# After modifying Dockerfiles
docker-compose build
docker-compose up -d
```

## Important Notes

1. **Legal Warning**: Only use this on devices you own or have explicit permission to test.
2. This environment is for educational purposes only.
3. Some security-related features may require rooted/jailbroken devices.
4. The system adapts to your platform but some tools may not work identically on all architectures. 