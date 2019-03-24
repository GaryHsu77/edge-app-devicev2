#!/bin/sh
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
# iptables -t nat -F
# iptables -t mangle -F
# iptables -F
# iptables -X
iptables -t filter -F MOXA-INPUT
iptables -t filter -F MOXA-FILTER
iptables -t filter -F MOXA-OUTPUT
iptables -t nat -F MOXA-PREROUTING
iptables -t nat -F MOXA-OUTPUT
iptables -t nat -F MOXA-POSTROUTING
iptables -t mangle -F MOXA-PREROUTING
iptables -t mangle -F MOXA-OUTPUT
iptables -t mangle -F MOXA-INPUT
iptables -t mangle -F MOXA-FORWARD
iptables -t mangle -F MOXA-POSTROUTING

iptables -t filter -X MOXA-INPUT
iptables -t filter -X MOXA-FILTER
iptables -t filter -X MOXA-OUTPUT
iptables -t nat -X MOXA-PREROUTING
iptables -t nat -X MOXA-OUTPUT
iptables -t nat -X MOXA-POSTROUTING
iptables -t mangle -X MOXA-PREROUTING
iptables -t mangle -X MOXA-OUTPUT
iptables -t mangle -X MOXA-INPUT
iptables -t mangle -X MOXA-FORWARD
iptables -t mangle -X MOXA-POSTROUTING

# iptables -t filter -N MOXA-INPUT
# iptables -t filter -N MOXA-FILTER
# iptables -t filter -N MOXA-OUTPUT
# iptables -t nat -N MOXA-PREROUTING
# iptables -t nat -N MOXA-OUTPUT
# iptables -t nat -N MOXA-POSTROUTING
# iptables -t mangle -N MOXA-PREROUTING
# iptables -t mangle -N MOXA-OUTPUT
# iptables -t mangle -N MOXA-INPUT
# iptables -t mangle -N MOXA-FORWARD
# iptables -t mangle -N MOXA-POSTROUTING

exit 0