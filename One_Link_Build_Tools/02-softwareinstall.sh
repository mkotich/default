#!/bin/sh

#Installing CrowdStrike Falcon
echo "Installing CrowdStrike Falcon..."
dpkg -i software/falcon-sensor_4.13.0-5803_amd64.deb
/opt/CrowdStrike/falconctl -s --cid=5144C1AF465E49D2879AB70D86C4AE5A-05
service falcon-sensor start

echo "Configuring rsyslog to report to QRadar server..."
echo "*.* @10.200.8.13:514" > /etc/rsyslog.d/99-qradar.conf
service rsyslog restart

echo ""
echo "System must be added to SolarWinds."
echo "Please contact your SolarWinds administrators and"
echo "have them install the SolarWinds Linux Agent on this"
echo "system."
