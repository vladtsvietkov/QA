#!/bin/sh
# Create links only when absent; apply declarative addresses and router rules.
set -eu
base=/etc/c4-network
ip netns list | grep -q '^c4-edge ' || ip netns add c4-edge
ip netns list | grep -q '^c4-node ' || ip netns add c4-node
if ! ip link show c4-up >/dev/null 2>&1; then
    ip link add c4-up type veth peer name c4-wan
    ip link set c4-wan netns c4-edge
    ip -n c4-edge link set c4-wan name uplink
fi
if ! ip -n c4-edge link show inside >/dev/null 2>&1; then
    ip link add c4-lan type veth peer name c4-end
    ip link set c4-lan netns c4-edge
    ip -n c4-edge link set c4-lan name inside
    ip link set c4-end netns c4-node
    ip -n c4-node link set c4-end name net0
fi
ip link set c4-up up
ip address replace 172.29.23.1/30 dev c4-up
ip -n c4-edge -batch "$base/edge.ip"
ip -n c4-node -batch "$base/node.ip"
ip netns exec c4-edge sysctl -w net.ipv4.ip_forward=1
ip netns exec c4-edge iptables-restore < "$base/edge.rules"
sysctl -w net.ipv4.ip_forward=1
iptables -C FORWARD -i c4-up -o enp0s3 -s 172.29.23.2/32 -j ACCEPT 2>/dev/null || iptables -I FORWARD 1 -i c4-up -o enp0s3 -s 172.29.23.2/32 -j ACCEPT
iptables -C FORWARD -i enp0s3 -o c4-up -d 172.29.23.2/32 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || iptables -I FORWARD 1 -i enp0s3 -o c4-up -d 172.29.23.2/32 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -t nat -C POSTROUTING -s 172.29.23.2/32 -o enp0s3 -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -s 172.29.23.2/32 -o enp0s3 -j MASQUERADE
