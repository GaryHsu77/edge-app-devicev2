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
        echo "/tmp/$d/data/* $d/data/"
    fi
done

export BUNDLES_HOME=/usr/lib/sanji-1.0
export BUNDLE_ENV=production

exec python /usr/lib/sanji-1.0/bootstrap/bootstrap.py