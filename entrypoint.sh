#!/bin/sh

echo "hello"

# set factory configs if first run.
BOOTSTRAP_DIR="/usr/lib/sanji-1.0/bootstrap/data"
if [ "$(ls -A .$BOOTSTRAP_DIR)" = "" ]; then
    echo "$BOOTSTRAP_DIR is Empty, init start ... "
    cp -r /tmp/sanji-1.0/bootstrap/data/* /usr/lib/sanji-1.0/bootstrap/data/
    cp -r /tmp/sanji-1.0/time/data/* /usr/lib/sanji-1.0/time/data/
    cp -r /tmp/sanji-1.0/service/data/* /usr/lib/sanji-1.0/service/data/
    cp -r /tmp/sanji-1.0/status/data/* /usr/lib/sanji-1.0/status/data/
    cp -r /tmp/sanji-1.0/serial/data/* /usr/lib/sanji-1.0/serial/data/
    cp -r /tmp/sanji-1.0/dhcpd/data/* /usr/lib/sanji-1.0/dhcpd/data/
    cp -r /tmp/sanji-1.0/cellular/data/* /usr/lib/sanji-1.0/cellular/data/
    cp -r /tmp/sanji-1.0/gps/data/* /usr/lib/sanji-1.0/gps/data/
    cp -r /tmp/sanji-1.0/openvpn/data/* /usr/lib/sanji-1.0/openvpn/data/
    cp -r /tmp/sanji-1.0/iptables/data/* /usr/lib/sanji-1.0/iptables/data/
    cp -r /tmp/sanji-1.0/remotecontrol/data/* /usr/lib/sanji-1.0/remotecontrol/data/
    cp -r /tmp/sanji-1.0/ethernet/data/* /usr/lib/sanji-1.0/ethernet/data/
    cp -r /tmp/sanji-1.0/dns/data/* /usr/lib/sanji-1.0/dns/data/
    cp -r /tmp/sanji-1.0/route/data/ /usr/lib/sanji-1.0/route/data/
    cp -r /tmp/sanji-1.0/modbus/data/ /usr/lib/sanji-1.0/modbus/data/
    cp -r /tmp/sanji-1.0/modbusslave/data/ /usr/lib/sanji-1.0/modbusslave/data/
    cp -r /tmp/sanji-1.0/logprofile/data/ /usr/lib/sanji-1.0/logprofile/data/
    cp -r /tmp/sanji-1.0/custom-equipment/data/ /usr/lib/sanji-1.0/custom-equipment/data/
    cp -r /tmp/sanji-1.0/import-export/data/ /usr/lib/sanji-1.0/import-export/data/
    cp -r /tmp/sanji-1.0/program/data/ /usr/lib/sanji-1.0/program/data/
    cp -r /tmp/sanji-1.0/upgrade/data/ /usr/lib/sanji-1.0/upgrade/data/
    cp -r /tmp/sanji-1.0/modbusawsiot/data/ /usr/lib/sanji-1.0/modbusawsiot/data/
    cp -r /tmp/sanji-1.0/mqtt/data/ /usr/lib/sanji-1.0/mqtt/data/
    cp -r /tmp/sanji-1.0/wifi/data/ /usr/lib/sanji-1.0/wifi/data/
    cp -r /tmp/sanji-1.0/azure/data/ /usr/lib/sanji-1.0/azure/data/
    cp -r /tmp/sanji-1.0/sparkplug/data/ /usr/lib/sanji-1.0/sparkplug/data/
    cp -r /tmp/sanji-1.0/aliyun/data/ /usr/lib/sanji-1.0/aliyun/data/
    cp -r /tmp/sanji-1.0/wonderware/data/ /usr/lib/sanji-1.0/wonderware/data/
fi

# export BUNDLES_HOME=/usr/lib/sanji-1.0
# export BUNDLE_ENV=production

/lib/systemd/systemd
