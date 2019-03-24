#!/bin/sh

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
    cp -r /tmp/sanji-1.0/route/data/* /usr/lib/sanji-1.0/route/data/
fi

export BUNDLES_HOME=/usr/lib/sanji-1.0
export BUNDLE_ENV=production

exec python /usr/lib/sanji-1.0/bootstrap/bootstrap.py
