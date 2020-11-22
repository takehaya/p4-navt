#!/bin/bash

# -- veth with no tagged vlan --
# VLAN100, 200:
#  veth1: 10.0.0.1/16, 02:03:04:05:06:01
# -- veth with tagged vlan --
# VLAN100:
#  veth10.100: 192.168.0.1/24, 02:03:04:05:06:11
#  veth11.100: 192.168.0.2/24, 02:03:04:05:06:12
# VLAN200:
#  veth21.200: 192.168.0.1/24, 02:03:04:05:06:21
#  veth22.200: 192.168.0.2/24, 02:03:04:05:06:22

set -eu

if [[ $(id -u) -ne 0 ]] ; then
    echo "Please run with sudo"
    exit 1
fi

run () {
    echo "$@"
    "$@" || exit 1
}

connect_p4 () {
    simple_switch_grpc --no-p4 -i 1@vtap1 \
    -i 2@vtap10 -i 3@vtap11 \
    -i 4@vtap21 -i 5@vtap22 \
    --log-console -L debug -- --grpc-server-addr 0.0.0.0:50051 --cpu-port 255 &
}

destroy_p4(){
    echo "destroy p4"
    ps aux | grep simple_switch_grpc | grep -v grep | awk '{ print "kill -9", $2 }' | sh
}

create_network () {
    HOST="host1"; VETH="veth1"; VTAP="vtap1"; VLAN="100"; VLAN_TYPE="port"; IPv4="10.0.0.1/16"; Mac="02:03:04:05:06:01";
    __create_network

    HOST="host11"; VETH="veth11"; VTAP="vtap11"; VLAN="100"; VLAN_TYPE="tag"; IPv4="192.168.0.1/24"; Mac="02:03:04:05:06:11";
    __create_network
    HOST="host12"; VETH="veth12"; VTAP="vtap12"; VLAN="100"; VLAN_TYPE="tag"; IPv4="192.168.0.2/24"; Mac="02:03:04:05:06:12";
    __create_network

    HOST="host21"; VETH="veth21"; VTAP="vtap21"; VLAN="200"; VLAN_TYPE="tag"; IPv4="192.168.0.1/24"; Mac="02:03:04:05:06:21";
    __create_network
    HOST="host22"; VETH="veth22"; VTAP="vtap22"; VLAN="200"; VLAN_TYPE="tag"; IPv4="192.168.0.2/24"; Mac="02:03:04:05:06:22";
    __create_network
}

__create_network () {
    echo "creating $HOST $VETH $VTAP $IPv4"
    # Create network namespaces
    run ip netns add $HOST
    # Create veth and assign to host
    run ip link add $VETH type veth peer name $VTAP
    run ip link set $VETH netns $HOST
    # Set MAC/IPv4/IPv6 address
    if [ $VLAN_TYPE == "port" ]; then
        run ip netns exec $HOST ip link set $VETH address $Mac
        run ip netns exec $HOST ip addr add $IPv4 dev $VETH
        #run ip netns exec $HOST ip -6 addr add db8::$VLAN:$num/64 dev $VETH
    else
        run ip netns exec $HOST ip link add link $VETH name $VETH.$VLAN type vlan id $VLAN
        run ip netns exec $HOST ip link set $VETH.$VLAN address $Mac
        run ip netns exec $HOST ip addr add $IPv4 dev $VETH.$VLAN
        #run ip netns exec $HOST ip -6 addr add db8::$VLAN:$num/64 dev $VETH.$VLAN
    fi
    # Link up loopback/veth/vtap
    run ip netns exec $HOST ip link set $VETH up
    run ip netns exec $HOST ifconfig lo up
    run ip link set dev $VTAP up

    # ipv6 disble. The reason being that it's a distraction during debugging.
    run ip netns exec $HOST sysctl -w net.ipv6.conf.all.disable_ipv6=1
}

destroy_network () {
    run ip netns del host1

    run ip netns del host11
    run ip netns del host12

    run ip netns del host21
    run ip netns del host22
}

stop () {
    destroy_network
    destroy_p4
}

trap stop 0 1 2 3 13 14 15

# exec functions
create_network
connect_p4

status=0; $SHELL || status=$?
exit $status
