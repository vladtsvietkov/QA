#!/bin/sh
# This isolated /24 test applies the lease only to its client interface.
case "$reason" in
  BOUND|REBOOT|RENEW|REBIND)
    ip address replace "$new_ip_address/24" dev "$interface"
    ip link set "$interface" up
    ip route replace default via "$new_routers" dev "$interface"
    ;;
esac
exit 0
