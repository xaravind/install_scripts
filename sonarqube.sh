#!/bin/bash

# Auto-elevate to root if not already
if [[ $EUID -ne 0 ]]; then
    echo "[INFO] Re-running script as root..."
    exec sudo "$0" "$@"
fi


LOGFILE="/var/log/setup_sonarqube.log"
exec > >(tee -a "$LOGFILE") 2>&1

# Stop on any error
set -e

echo "========== Script started at $(date) =========="

# Update system
echo "[INFO] Updating system..."
sudo yum update -y

# Install unzip
echo "[INFO] Installing unzip..."
sudo yum install -y unzip

# Install Amazon Corretto 17 JDK
echo "[INFO] Installing Amazon Corretto 17 JDK..."
sudo yum install -y java-17-amazon-corretto-devel.x86_64

# Create sonar user
echo "[INFO] Creating sonar user..."
sudo useradd -m sonar || echo "[INFO] User already exists."

# Switch to /opt directory
cd /opt

# Download SonarQube
echo "[INFO] Downloading SonarQube..."
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-25.4.0.105899.zip

# Verify download
if [ ! -f sonarqube-25.4.0.105899.zip ]; then
    echo "[ERROR] SonarQube download failed!"
    exit 1
fi

# Extract SonarQube
echo "[INFO] Extracting SonarQube..."
sudo unzip sonarqube-25.4.0.105899.zip
sudo mv sonarqube-25.4.0.105899 sonarqube
sudo chown -R sonar:sonar /opt/sonarqube
sudo rm -f sonarqube-25.4.0.105899.zip

# Start SonarQube
echo "[INFO] Starting SonarQube..."
cd /opt/sonarqube/bin/linux-x86-64
sudo -u sonar ./sonar.sh start

# Check SonarQube status
echo "[INFO] Checking SonarQube status..."
sudo -u sonar ./sonar.sh status

# Verify process
if ps aux | grep -v grep | grep sonar > /dev/null; then
    echo "[SUCCESS] SonarQube started successfully!"
else
    echo "[ERROR] SonarQube failed to start!"
    exit 1
fi

echo "[INFO] SonarQube installation and setup completed successfully!"
echo "========== Script ended at $(date) =========="
