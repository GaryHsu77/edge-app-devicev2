################################################################################
# qemu
################################################################################
FROM docker.moxa.online/build-armhf/base:stretch as qemu

################################################################################
# rootfs
################################################################################
FROM arm32v7/debian:9 as rootfs

WORKDIR /var/thingspro/

COPY --from=qemu /usr/bin/qemu-arm-static /usr/bin/

# install thingspro frm
ARG REPO_URL=http://repo.moxa.online/static/ThingsPro/Gateway/unstable/XXX/
ARG FRM_FILE=thingspro_develop_ARCH_DATE.frm
RUN set -x && \
    apt-get update && apt-get install -q -y --force-yes --fix-missing wget dpkg-dev dbus systemd && \
    wget ${REPO_URL}/${FRM_FILE} && \
    tar zxf ./${FRM_FILE} && \
    tar zxf thingspro_release-thingspro_v2.6_armhf.pkg && \
    mkdir -p /tmp/archive && \
    tar zxf archive.tar.gz -C /tmp/archive/ && \
    cd /tmp/archive/ && \
    dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz && \
    echo 'deb file:///tmp/archive ./' >  /etc/apt/sources.list.d/tp.list && \
    apt-get update && apt-cache search tp-device-app && \
    apt-get update && apt-get install -y -o Dpkg::Options::="--force-confnew" --allow-unauthenticated tp-device-app; rm -rf /var/lib/apt/lists/*  && \
    dpkg --purge --force-all udev build-essential && \
    find / -name "*.a" -delete && \
    cd /usr/share && rm -rf man doc locale icons && \
    rm -rf /lib/udev && \
    rm -rf /tmp/* && \
    rm -rf /var/thingspro/

# copy factory configs
RUN mkdir -p /opt/usr/lib/sanji-1.0 && cp -rf /usr/lib/sanji-1.0 /opt/usr/lib/

# override fs
ADD root /

# https://github.com/solita/docker-systemd/blob/master/Dockerfile
# Don't start any optional services except for the few we need.
RUN find /etc/systemd/system \
    /lib/systemd/system \
    -path '*.wants/*' \
    -not -name '*journald*' \
    -not -name '*systemd-tmpfiles*' \
    -not -name '*systemd-user-sessions*' \
    -exec rm \{} \;
ENV container docker
ENV LC_ALL C
RUN systemctl set-default multi-user.target
COPY setup /sbin/
STOPSIGNAL SIGRTMIN+3

RUN rm -f /usr/bin/qemu-arm-static /etc/apt/apt.conf.d/00-temp-cache-apt

# CMD ["/bin/bash", "-c", "exec /sbin/init --log-target=journal 3>&1"]
CMD ["/lib/systemd/systemd"]
