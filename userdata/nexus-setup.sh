#!/bin/bash

# 1. Install Java 17 and other requirements
yum install -y java-17-amazon-corretto wget tar rsync

# 2. Set up paths
NEXUS_HOME="/opt/nexus"
TMPDIR="/tmp/nexus"
NEXUS_URL="https://download.sonatype.com/nexus/3/latest-unix.tar.gz"

# 3. Create directories
mkdir -p "$NEXUS_HOME"
mkdir -p "$TMPDIR"
cd "$TMPDIR"

# 4. Download and extract Nexus
wget "$NEXUS_URL" -O nexus.tar.gz
tar xzvf nexus.tar.gz
NEXUSDIR=$(ls -d nexus-*/ | head -n 1 | cut -d/ -f1)
rsync -avz "$NEXUSDIR/" "$NEXUS_HOME/"
rm -rf "$TMPDIR"

# 5. Create Nexus user & permissions
id nexus &>/dev/null || useradd --system --no-create-home nexus
chown -R nexus:nexus "$NEXUS_HOME"

# 6. Ensure Nexus runs as nexus user
echo 'run_as_user="nexus"' > "$NEXUS_HOME/bin/nexus.rc"

# 7. Set up systemd service
cat > /etc/systemd/system/nexus.service <<EOT
[Unit]
Description=Sonatype Nexus Repository Manager
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=$NEXUS_HOME/bin/nexus start
ExecStop=$NEXUS_HOME/bin/nexus stop
User=nexus
Restart=on-failure
TimeoutSec=600

[Install]
WantedBy=multi-user.target
EOT

# 8. Enable and start the service
systemctl daemon-reload
systemctl enable nexus
systemctl start nexus

# 9. Firewall (if enabled, open port 8081)
if systemctl status firewalld &>/dev/null; then
    firewall-cmd --add-port=8081/tcp --permanent
    firewall-cmd --reload
fi

echo "Nexus installed & running. Access: http://<your-server-ip>:8081"
