#!/bin/bash

# Auto-elevate to root if not already
if [[ $EUID -ne 0 ]]; then
    echo "[INFO] Re-running script as root..."
    exec sudo "$0" "$@"
fi



LOGFILE="/var/log/setup_jenkins_maven.log"
exec > >(tee -a "$LOGFILE") 2>&1

# Uncomment to stop script on any error
set -e

echo "========== Script started at $(date) =========="

# Update system
echo "[INFO] Updating system..."
sudo yum update -y

# Install Amazon Corretto 21 JDK
echo "[INFO] Installing Amazon Corretto 21 JDK..."
sudo yum install java-21-amazon-corretto-devel.x86_64 -y

# Install Maven for Amazon Corretto 21
echo "[INFO] Installing Maven for Amazon Corretto 21..."
sudo yum install maven-amazon-corretto21.noarch -y

# Install unzip if not present
echo "[INFO] Installing unzip..."
sudo yum install unzip -y

# Install Jenkins repository
echo "[INFO] Adding Jenkins repository..."
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Install Jenkins
echo "[INFO] Installing Jenkins..."
sudo yum install jenkins -y

# Reload systemd manager configuration
echo "[INFO] Reloading systemd daemon..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload

# Start Jenkins service
echo "[INFO] Starting Jenkins..."
sudo systemctl start jenkins

# Enable Jenkins to start on boot
sudo systemctl enable jenkins

# Check Jenkins status
echo "[INFO] Checking Jenkins status..."
if systemctl is-active --quiet jenkins; then
    echo "[SUCCESS] Jenkins started successfully!"
else
    echo "[ERROR] Jenkins failed to start!"
    exit 1
fi

echo "[INFO] Installation completed successfully!"
echo "========== Script ended at $(date) =========="
