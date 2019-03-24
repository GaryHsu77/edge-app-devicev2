################################################################################
# qemu
################################################################################
FROM docker.moxa.online/build-armhf/base:stretch as qemu

################################################################################
# cellular-pkg patch
################################################################################
FROM arm32v7/debian:9 as cellularpkg

COPY --from=qemu /usr/bin/qemu-arm-static /usr/bin/

RUN apt-get update && apt-get install -q -y --force-yes --fix-missing wget gnupg2 && \
    rm -rf /var/lib/apt/lists/* && \
    wget -O- http://repo.isd.moxa.com/gpg | apt-key add -

RUN sed -i 's/deb.debian.org/cdn-fastly.deb.debian.org/g' /etc/apt/sources.list && \
    echo "deb [trusted=yes] http://repo.isd.moxa.com/debian/stretch/3rd-party/thingspro_v2.5 utility main" > /etc/apt/sources.list.d/thingspro.list && \
    echo "deb [trusted=yes] http://repo.isd.moxa.com/debian/stretch/thingspro release thingspro_v2.5" >> /etc/apt/sources.list.d/thingspro.list && \
    apt-get update && \
    apt-get install -qy \
        sanji-bundle-cellular

################################################################################
# rootfs
################################################################################
FROM arm32v7/debian:8 as rootfs

COPY --from=qemu /usr/bin/qemu-arm-static /usr/bin/

RUN apt-get update && apt-get install -q -y --force-yes --fix-missing wget && \
    rm -rf /var/lib/apt/lists/* && \
    wget -O- http://repo.isd.moxa.com/gpg | apt-key add - && \
    wget -O- http://repo.mosquitto.org/debian/mosquitto-repo.gpg.key | apt-key add - && \
    apt-get remove -y wget

RUN sed -i 's/deb.debian.org/cdn-fastly.deb.debian.org/g' /etc/apt/sources.list && \
    echo "deb [trusted=yes] http://repo.isd.moxa.com/debian/jessie/3rd-party/thingspro_v2.5 utility main" >> /etc/apt/sources.list.d/thingspro.list && \
    echo "deb [trusted=yes] http://repo.isd.moxa.com/debian/jessie/thingspro unstable main" >> /etc/apt/sources.list.d/thingspro.list && \
    echo "deb [trusted=yes] http://repo.isd.moxa.com/debian/jessie/thingspro stable main" >> /etc/apt/sources.list.d/thingspro.list && \
    echo "deb [trusted=yes] http://repo.mosquitto.org/debian jessie main" >> /etc/apt/sources.list.d/thingspro.list && \
    apt-get update && \
    apt-get install -qy \
        sanji-bundle-bootstrap sanji-bundle-time sanji-bundle-status \
        sanji-bundle-serial \
        sanji-bundle-dns sanji-bundle-dhcpd sanji-bundle-ethernet \
        sanji-bundle-cellular sanji-bundle-gps sanji-bundle-route \
        sanji-bundle-openvpn sanji-bundle-iptables \
        sanji-bundle-remotecontrol

RUN apt-get install -qy monit
RUN apt-get install -qy libmxtagf-dev libsanji
RUN apt-get install -qy vim avahi-daemon iptables
RUN apt-get install -qy uc8100-setinterface
RUN ldconfig -v

COPY --from=cellularpkg /usr/lib/sanji-1.0/cellular/ /usr/lib/sanji-1.0/cellular/
COPY --from=cellularpkg /etc/moxa-cellular-utils/ /etc/moxa-cellular-utils/
COPY --from=cellularpkg /usr/sbin/cell_mgmt /usr/sbin/cell_mgmt

# apt-get remove -y `dpkg-query -W -f '${Package}\n' | grep -- '-dev$' | xargs` && \
# apt-get remove -y udev
RUN set -x && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get remove -y build-essential && \
    apt-get autoremove -y && \
    dpkg --purge --force-all \
        udev \
        build-essential \
        `dpkg-query -W -f '${Package}\n' | grep -- '-dev$' | grep -v libmx | xargs` && \
    find / -name "*.a" -delete && \
    cd /usr/share && rm -rf man doc locale icons && \
    rm -rf /lib/udev 


# RUN dpkg --purge --force-all mxfieldbus mxfbmodbus libmxidaf-py libmxdaf-dev
# https://github.com/j8r/dockerfiles/blob/master/systemd/debian/8/Dockerfile
RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup* \
    /lib/systemd/system/systemd-update-utmp* \
    /usr/sbin/mxsysstatusd \
    /etc/systemd/system/mxsysstatusd.service

RUN rm -f /usr/bin/qemu-arm-static /etc/apt/apt.conf.d/00-temp-cache-apt

################################################################################
# combine
################################################################################
FROM scratch

COPY --from=rootfs / /
ADD root /

COPY --from=qemu /usr/bin/qemu-arm-static /usr/bin/

# iptables prepare
RUN mkdir -p /etc/iptables && \
    chmod +x /usr/lib/sanji-1.0/iptables/tools/flush.sh && \
    echo "" > /etc/iptables/up.rules && \
    chmod +x /etc/iptables/up.rules && \
    echo "" > /etc/iptables/run.sh && \
    chmod +x /etc/iptables/run.sh

# copy factory configs
RUN mkdir -p /tmp/sanji-1.0/bootstrap/data/ && \
    cp -r /usr/lib/sanji-1.0/bootstrap/data/* /tmp/sanji-1.0/bootstrap/data/ && \
    mkdir -p /tmp/sanji-1.0/time/data/ && \
    cp -r /usr/lib/sanji-1.0/time/data/* /tmp/sanji-1.0/time/data/ && \
    mkdir -p /tmp/sanji-1.0/status/data/ && \
    cp -r /usr/lib/sanji-1.0/status/data/* /tmp/sanji-1.0/status/data/ && \
    mkdir -p /tmp/sanji-1.0/serial/data/ && \
    cp -r /usr/lib/sanji-1.0/serial/data/* /tmp/sanji-1.0/serial/data/ && \
    mkdir -p /tmp/sanji-1.0/dns/data/ && \
    cp -r /usr/lib/sanji-1.0/dns/data/* /tmp/sanji-1.0/dns/data/ && \
    mkdir -p /tmp/sanji-1.0/dhcpd/data/ && \
    cp -r /usr/lib/sanji-1.0/dhcpd/data/* /tmp/sanji-1.0/dhcpd/data/ && \
    mkdir -p /tmp/sanji-1.0/ethernet/data/ && \
    cp -r /usr/lib/sanji-1.0/ethernet/data/* /tmp/sanji-1.0/ethernet/data/ && \
    mkdir -p /tmp/sanji-1.0/cellular/data/ && \
    cp -r /usr/lib/sanji-1.0/cellular/data/* /tmp/sanji-1.0/cellular/data/ && \
    mkdir -p /tmp/sanji-1.0/gps/data/ && \
    cp -r /usr/lib/sanji-1.0/gps/data/* /tmp/sanji-1.0/gps/data/ && \
    mkdir -p /tmp/sanji-1.0/route/data/ && \
    cp -r /usr/lib/sanji-1.0/route/data/* /tmp/sanji-1.0/route/data/ && \
    mkdir -p /tmp/sanji-1.0/openvpn/data/ && \
    cp -r /usr/lib/sanji-1.0/openvpn/data/* /tmp/sanji-1.0/openvpn/data/ && \
    mkdir -p /tmp/sanji-1.0/iptables/data/ && \
    cp -r /usr/lib/sanji-1.0/iptables/data/* /tmp/sanji-1.0/iptables/data/ && \
    mkdir -p /tmp/sanji-1.0/remotecontrol/data/ && \
    cp -r /usr/lib/sanji-1.0/remotecontrol/data/* /tmp/sanji-1.0/remotecontrol/data/

RUN rm -f /usr/bin/qemu-arm-static /etc/apt/apt.conf.d/00-temp-cache-apt

# WORKDIR /usr/src/app
# CMD [ "/usr/local/sbin/app.sh" ]

VOLUME [ "/sys/fs/cgroup" ]
ENV container docker
ENV LC_ALL C

CMD ["/lib/systemd/systemd"]
