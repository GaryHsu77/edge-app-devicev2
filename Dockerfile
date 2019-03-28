################################################################################
# rootfs
################################################################################
FROM amd64/debian:8 as rootfs
ARG REPO_URL=http://repo.moxa.online/static/ThingsPro/Gateway/unstable/XXX/
ARG FRM_FILE=thingspro_develop_ARCH_DATE.frm
WORKDIR /var/thingspro/

RUN set -x && \
    apt-get update && apt-get install -q -y --force-yes --fix-missing wget dpkg-dev dbus && \
    wget ${REPO_URL}/${FRM_FILE} && \
    tar zxf ./${FRM_FILE} && \
    tar zxf thingspro_v2.5.1-jessie_amd64.pkg && \
    mkdir -p /tmp/archive && \
    tar zxf archive.tar.gz -C /tmp/archive/ && \
    cd /tmp/archive/ && \
    dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz && \
    echo 'deb file:/tmp/archive ./' >  /etc/apt/sources.list.d/tp.list && \
    apt-get update && apt-cache search mxcloud

VOLUME [ "/sys/fs/cgroup" ]
ENV container docker
ENV LC_ALL C
RUN systemctl set-default multi-user.target
RUN apt-get update && apt-get install -q -y --force-yes --fix-missing --allow-unauthenticated mc1121-mxcloud-cg

RUN rm -rf /var/lib/apt/lists/* && \
    dpkg --purge --force-all udev build-essential && \
    find / -name "*.a" -delete && \
    cd /usr/share && rm -rf man doc locale icons && \
    rm -rf /lib/udev && \
    rm -rf /tmp/* && \
    rm -rf /var/thingspro/
RUN ldconfig -v

# https://github.com/solita/docker-systemd/blob/master/Dockerfile
# Don't start any optional services except for the few we need.
RUN find /etc/systemd/system \
    /lib/systemd/system \
    -path '*.wants/*' \
    -not -name '*journald*' \
    -not -name '*systemd-tmpfiles*' \
    -not -name '*systemd-user-sessions*' \
    -exec rm \{} \;

################################################################################
# combine
################################################################################
FROM scratch as combine

ADD root /

COPY --from=rootfs / /
# copy factory configs
COPY --from=rootfs /usr/lib/sanji-1.0 /tmp/usr/lib/sanji-1.0

ENV container docker
ENV LC_ALL C
RUN systemctl set-default multi-user.target
COPY setup /sbin/
STOPSIGNAL SIGRTMIN+3
CMD ["/bin/bash", "-c", "exec /sbin/init --log-target=journal 3>&1"]
