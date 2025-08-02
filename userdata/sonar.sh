#!/bin/bash
set -e

# Configurable parameters
SONARQUBE_VERSION="25.2.0.102705"
SONARQUBE_ZIP="sonarqube-${SONARQUBE_VERSION}.zip"
SONARQUBE_URL="https://binaries.sonarsource.com/Distribution/sonarqube/${SONARQUBE_ZIP}"
SONARQUBE_DIR="/opt/sonarqube"
SONAR_DB="sonarqube"
SONAR_DB_USER="sonar"
SONAR_DB_PASS="password@123"

echo "==> Updating system and installing dependencies..."
apt update
apt install -y openjdk-17-jdk unzip wget postgresql postgresql-contrib

echo "==> Configuring system limits for sonarqube..."

# Elasticsearch requires this value
tee /etc/sysctl.d/99-sonarqube.conf > /dev/null <<EOT
vm.max_map_count=262144
fs.file-max=65536
EOT

sysctl --system

tee /etc/security/limits.d/99-sonarqube.conf > /dev/null <<EOT
sonarqube   -   nofile   65536
sonarqube   -   nproc    4096
EOT

echo "==> Creating SonarQube system user..."
id sonarqube &>/dev/null || adduser --system --no-create-home --group --disabled-login sonarqube

echo "==> Setting up PostgreSQL user and database..."
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='${SONAR_DB_USER}'" | grep -q 1 || \
sudo -u postgres psql -c "CREATE USER ${SONAR_DB_USER} WITH ENCRYPTED PASSWORD '${SONAR_DB_PASS}';"

sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw ${SONAR_DB} || \
sudo -u postgres psql -c "CREATE DATABASE ${SONAR_DB} OWNER ${SONAR_DB_USER} TEMPLATE template0 ENCODING 'UTF8';"

echo "==> Downloading SonarQube version ${SONARQUBE_VERSION}..."
wget -q ${SONARQUBE_URL} -O /tmp/${SONARQUBE_ZIP}
unzip -q -d /tmp /tmp/${SONARQUBE_ZIP}
mv /tmp/sonarqube-${SONARQUBE_VERSION} ${SONARQUBE_DIR}

chown -R sonarqube:sonarqube ${SONARQUBE_DIR}

echo "==> Configuring SonarQube database connection..."
cat >> ${SONARQUBE_DIR}/conf/sonar.properties <<EOL


# PostgreSQL database settings
sonar.jdbc.username=${SONAR_DB_USER}
sonar.jdbc.password=${SONAR_DB_PASS}
sonar.jdbc.url=jdbc:postgresql://localhost:5432/${SONAR_DB}
EOL

chown sonarqube:sonarqube ${SONARQUBE_DIR}/conf/sonar.properties

echo "==> Creating systemd service file..."
cat > /etc/systemd/system/sonarqube.service <<EOF
[Unit]
Description=SonarQube service
After=network.target

[Service]
Type=forking
ExecStart=${SONARQUBE_DIR}/bin/linux-x86-64/sonar.sh start
ExecStop=${SONARQUBE_DIR}/bin/linux-x86-64/sonar.sh stop
User=sonarqube
Group=sonarqube
Restart=on-failure
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF

echo "==> Reloading systemd and starting SonarQube..."
systemctl daemon-reload
systemctl enable sonarqube
systemctl start sonarqube

echo "==> Installation complete!"
echo "Wait a minute or two, then access SonarQube at: http://<your-server-ip>:9000"
echo "Default login: admin / admin"
echo "Check service status: sudo systemctl status sonarqube"
echo "View logs: sudo tail -f ${SONARQUBE_DIR}/logs/sonar.log"
