################################################################################
# qemu
################################################################################
FROM docker.moxa.online/build-armhf/base:stretch as qemu

################################################################################
# rootfs
################################################################################
FROM arm32v7/debian:9 as rootfs
ARG REPO_URL=http://repo.moxa.online/static/ThingsPro/Gateway/unstable/XXX/
ARG FRM_FILE=thingspro_develop_ARCH_DATE.frm
WORKDIR /var/thingspro/

COPY --from=qemu /usr/bin/qemu-arm-static /usr/bin/

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

# install thingspro frm
RUN set -x && \
    apt-get update && apt-get install -q -y --force-yes --fix-missing wget dpkg-dev dbus && \
    wget ${REPO_URL}/${FRM_FILE} && \
    tar zxf ./${FRM_FILE} && \
    tar zxf thingspro_develop_armhf.pkg && \
    mkdir -p /tmp/archive && \
    tar zxf archive.tar.gz -C /tmp/archive/ && \
    cd /tmp/archive/ && \
    dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz && \
    echo 'deb file:/tmp/archive ./' >  /etc/apt/sources.list.d/tp.list && \
    apt-get update && apt-cache search mxcloud && \
    apt-get update && apt-get install -q -y --force-yes --fix-missing --allow-unauthenticated uc8100ame-mxcloud-cg; rm -rf /var/lib/apt/lists/*  && \
    dpkg --purge --force-all udev build-essential && \
    find / -name "*.a" -delete && \
    cd /usr/share && rm -rf man doc locale icons && \
    rm -rf /lib/udev && \
    rm -rf /tmp/* && \
    rm -rf /var/thingspro/

# copy factory configs
RUN mkdir -p /tmp/usr/lib/sanji-1.0 && cp -r /usr/lib/sanji-1.0 /tmp/usr/lib/sanji-1.0

# override fs
ADD root /

RUN systemctl set-default multi-user.target

COPY setup /sbin/
STOPSIGNAL SIGRTMIN+3

RUN rm -f /usr/bin/qemu-arm-static /etc/apt/apt.conf.d/00-temp-cache-apt

# CMD ["/bin/bash", "-c", "exec /sbin/init --log-target=journal 3>&1"]
CMD ["/lib/systemd/systemd"]
