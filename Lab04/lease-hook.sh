#!/bin/sh
# Keep the acquired /24 address and router for the test node.
if [ "$reason" = BOUND ] || [ "$reason" = REBOOT ]; then
    ip address replace "$new_ip_address/24" dev "$interface"
    ip route replace default via "$new_routers" dev "$interface"
fi
exit 0
