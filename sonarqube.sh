#!/bin/bash

LOGFILE="/var/log/setup_sonarqube.log"
exec > >(tee -a "$LOGFILE") 2>&1

# Uncomment to stop script on any error
set -e

echo "========== Script started at $(date) =========="

# Update system
echo "[INFO] Updating system..."
sudo apt update -y

# Install unzip if not present
echo "[INFO] Installing unzip..."
sudo apt install -y unzip

# Install OpenJDK 17 (required for SonarQube)
echo "[INFO] Installing OpenJDK 17..."
sudo apt install openjdk-17-jre-headless -y

# Download SonarQube
echo "[INFO] Downloading SonarQube..."
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-25.4.0.105899.zip

# Check if SonarQube download was successful
if [ ! -f sonarqube-25.4.0.105899.zip ]; then
    echo "[ERROR] SonarQube download failed!"
    exit 1
fi

# Unzip SonarQube
echo "[INFO] Extracting SonarQube..."
unzip sonarqube-25.4.0.105899.zip

# Change to SonarQube directory
cd sonarqube-25.4.0.105899/bin/linux-x86-64

# Start SonarQube
echo "[INFO] Starting SonarQube..."
./sonar.sh start

# Check if SonarQube started successfully
echo "[INFO] Checking SonarQube status..."
./sonar.sh status

# Verify if SonarQube is running
if ps aux | grep -v grep | grep sonar > /dev/null; then
    echo "[SUCCESS] SonarQube started successfully!"
else
    echo "[ERROR] SonarQube failed to start!"
    exit 1
fi

echo "[INFO] SonarQube installation and setup completed successfully!"
echo "========== Script ended at $(date) =========="
