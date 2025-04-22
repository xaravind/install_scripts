#!/bin/bash

LOGFILE="/var/log/setup_nexus_tomcat.log"
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

# Install unzip if not present
echo "[INFO] Installing unzip..."
sudo yum install unzip -y

# Install Nexus
echo "[INFO] Installing Nexus..."
cd /opt
sudo wget https://download.sonatype.com/nexus/3/nexus-3.79.1-04-linux-x86_64.tar.gz

# Check if Nexus download was successful
if [ ! -f nexus-3.79.1-04-linux-x86_64.tar.gz ]; then
    echo "[ERROR] Nexus download failed!"
    exit 1
fi

# Extract and set up Nexus
echo "[INFO] Extracting Nexus..."
sudo tar -xvf nexus-3.79.1-04-linux-x86_64.tar.gz

# Create Nexus user
echo "[INFO] Creating Nexus user..."
sudo useradd nexus

# Change ownership and clean up
echo "[INFO] Changing ownership and cleaning up..."
sudo rm -rf nexus-3.79.1-04-linux-x86_64.tar.gz
sudo mv nexus-* nexus
sudo chown -R nexus:nexus /opt/nexus
sudo chown -R nexus:nexus /opt/sonatype-work

# Create Nexus service file
echo "[INFO] Creating Nexus service file..."
sudo cat > /etc/systemd/system/nexus.service << 'EOF'
[Unit]
Description=nexus service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop
User=nexus
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

# Start and enable Nexus service
echo "[INFO] Starting Nexus service..."
sudo systemctl daemon-reload
sudo systemctl enable nexus
sudo systemctl start nexus

# Check if Nexus started successfully
if sudo systemctl is-active --quiet nexus; then
    echo "[SUCCESS] Nexus started successfully!"
else
    echo "[ERROR] Nexus failed to start!"
    exit 1
fi

# Install Tomcat
echo "[INFO] Downloading and Installing Tomcat..."
cd /opt
sudo wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.100/bin/apache-tomcat-9.0.100.zip

# Check if Tomcat download was successful
if [ ! -f apache-tomcat-9.0.100.zip ]; then
    echo "[ERROR] Tomcat download failed!"
    exit 1
fi

# Extract Tomcat and set permissions
echo "[INFO] Extracting Tomcat..."
sudo unzip apache-tomcat-9.0.100.zip
sudo chmod 755 /opt/apache-tomcat-9.0.100/bin/*.sh

# Clean up downloaded Tomcat zip file
echo "[INFO] Cleaning up Tomcat zip file..."
sudo rm apache-tomcat-9.0.100.zip

# Changing default Tomcat port from 8080 to 8090
echo "[INFO] Changing Tomcat default port to 8090..."
sudo sed -i 's/8080/8090/g' /opt/apache-tomcat-9.0.100/conf/server.xml

# Starting Tomcat
echo "[INFO] Starting Tomcat..."
sudo /opt/apache-tomcat-9.0.100/bin/startup.sh

# Check if Tomcat started successfully
if ps aux | grep -v grep | grep tomcat > /dev/null; then
    echo "[SUCCESS] Tomcat started successfully!"
else
    echo "[ERROR] Tomcat failed to start!"
    exit 1
fi

echo "[INFO] Installation completed successfully!"
echo "========== Script ended at $(date) =========="
