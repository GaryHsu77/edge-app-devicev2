#!/bin/sh

echo "**********************************************************************"
echo "**********************************************************************"
echo "         #######   ######  ###   ###  ####   ####  #####              "
echo "          ##    #  ###      ##   ##    ##   ##     ##                 "
echo "          ##    #  ######   ##   ##    ##   ##     #####              "
echo "          ##    #  ###       ## ##     ##   ##     ##                 "
echo "          ##    #  ###        ###      ##   ##     ##                 "
echo "        ########   #######     #     #####   ####  #######            "
echo "**********************************************************************"
echo "**********************************************************************"

# copy factory configs if service data folder is empty.
for d in /usr/lib/sanji-1.0/* ; do
    mkdir -p $d/data
    if [ "$(ls -A $d/data)" = "" ]; then
        cp -r "/tmp/$d/data/* $d/data/"
    fi
done

systemctl set-environment HTTP_PORT=${HTTP_PORT} HTTPS_PORT=${HTTPS_PORT}
systemctl start thingspro-gateway-web-service
systemctl start watchdog.service
systemctl start monit.service
systemctl start mosquitto.service

export BUNDLES_HOME=/usr/lib/sanji-1.0
export BUNDLE_ENV=production
export MX_DATA_LOG_PATH=/var/mxc

exec python /usr/lib/sanji-1.0/bootstrap/bootstrap.py