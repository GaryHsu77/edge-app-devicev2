#!/bin/sh

echo "hello"

# set factory configs if first run.
BOOTSTRAP_DIR="/usr/lib/sanji-1.0"
if [ "$(ls -A .$BOOTSTRAP_DIR)" = "" ]; then
    echo "$BOOTSTRAP_DIR is Empty, init start ... "
    cp -r /tmp/sanji-1.0/* /usr/lib/sanji-1.0/
fi

# export BUNDLES_HOME=/usr/lib/sanji-1.0
# export BUNDLE_ENV=production

/lib/systemd/systemd
