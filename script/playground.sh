#!/bin/bash

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
    simple_switch_grpc --no-p4 \
    -i 1@veth-NAVT-NERT -i 2@br0-NAVT-GW \
    --log-console -L trace -- --grpc-server-addr 0.0.0.0:50051 --cpu-port 255 &
}

# connect_p4 () {
#     simple_switch ./build.bmv2/switch.json \
#     -i 1@veth-NAVT-NERT -i 2@br0-NAVT-GW \
#     --log-console -L trace &
# }


destroy_p4(){
    echo "destroy p4"
    ps aux | grep simple_switch_grpc | grep -v grep | awk '{ print "kill -9", $2 }' | sh
}

# destroy_p4(){
#     echo "destroy p4"
#     ps aux | grep simple_switch | grep -v grep | awk '{ print "kill -9", $2 }' | sh
# }

create_network () {
    create_external
    create_navt
    create_internal
}

create_external(){
    # setup namespaces
    run ip netns add NOC
    run ip netns add NERT

    # setup veth peer
    run ip link add veth-NOC-NERT type veth peer name veth-NERT-NOC
    run ip link set veth-NOC-NERT netns NOC
    run ip link set veth-NERT-NOC netns NERT

    run ip link add veth-NERT-NAVT type veth peer name veth-NAVT-NERT
    run ip link set veth-NERT-NAVT netns NERT

    # NOC configuraiton
    run ip netns exec NOC ip addr add 172.31.50.1/24 dev veth-NOC-NERT
    run ip netns exec NOC ip link set veth-NOC-NERT up
    run ip netns exec NOC ip route add default via 172.31.50.254

    # NERT configuration
    run ip netns exec NERT ip addr add 172.31.50.254/24 dev veth-NERT-NOC
    run ip netns exec NERT ip addr add 172.27.1.1/24 dev veth-NERT-NAVT

    run ip netns exec NERT ip link set veth-NERT-NOC up
    run ip netns exec NERT ip link set veth-NERT-NAVT up
    run ip netns exec NERT ip link set lo up

    run ip netns exec NERT ip link set addr 02:03:04:05:06:01 dev veth-NERT-NAVT
    # run ip netns exec NERT ip neigh add 172.27.1.254 lladdr 02:03:04:05:06:fe dev veth-NERT-NAVT
    run ip netns exec NERT ip route add 10.1.0.0/16 via 172.27.1.254 dev veth-NERT-NAVT
    run ip netns exec NERT ip route add 10.2.0.0/16 via 172.27.1.254 dev veth-NERT-NAVT

    # sysctl for NERT
    run ip netns exec NERT sysctl net.ipv4.ip_forward=1
    run ip netns exec NERT sysctl net.ipv4.conf.all.rp_filter=0
}

create_navt(){
    run ip link set dev veth-NAVT-NERT up

    run ip link add name br0 type bridge
    run ip link add br0-NAVT-GW type veth peer name br0-GW-NAVT
    run ip link add br0-NAVT-AG type veth peer name br0-AG-NAVT
    run ip link add br0-NAVT-BG type veth peer name br0-BG-NAVT
    run ip link set dev br0-GW-NAVT master br0
    run ip link set dev br0-NAVT-AG master br0
    run ip link set dev br0-NAVT-BG master br0

    run ip link set br0-GW-NAVT up
    run ip link set br0-NAVT-GW up
    run ip link set br0-NAVT-AG up
    run ip link set br0-NAVT-BG up
    run ip link set br0 up
    # run ip addr add 172.26.2.254/24 dev br0-NAVT-GW
    # run ip addr add 172.27.1.254/24 dev veth-NAVT-NERT
    run ip link set addr 02:03:04:05:06:fe dev br0-NAVT-GW
    run ip link set addr 02:03:04:05:06:fe dev veth-NAVT-NERT

    run sysctl net.ipv4.ip_forward=1
}

create_internal(){
    # setup namespaces
    run ip netns add AG
    run ip netns add AC
    run ip netns add BG
    run ip netns add BC

    # set gw interface
    run ip link set br0-AG-NAVT netns AG
    run ip link set br0-BG-NAVT netns BG
    run ip netns exec AG ip link set br0-AG-NAVT up
    run ip netns exec BG ip link set br0-BG-NAVT up

    # vlan setting
    run ip netns exec AG ip link add link br0-AG-NAVT name br0-AG-NAVT.100 type vlan id 100
    run ip netns exec BG ip link add link br0-BG-NAVT name br0-BG-NAVT.200 type vlan id 200

    # veth peer
    run ip link add veth-AG-AC type veth peer name veth-AC-AG
    run ip link add veth-BG-BC type veth peer name veth-BC-BG

    run ip link set veth-AG-AC netns AG
    run ip link set veth-AC-AG netns AC
    run ip link set veth-BG-BC netns BG
    run ip link set veth-BC-BG netns BC

    # sysctl
    run ip netns exec AG sysctl net.ipv4.ip_forward=1
    run ip netns exec BG sysctl net.ipv4.ip_forward=1

    # settings for A gateway
    run ip netns exec AG ip link set addr 02:03:04:05:06:11 dev br0-AG-NAVT.100

    run ip netns exec AG ip addr add 172.26.2.1/24 dev br0-AG-NAVT.100
    run ip netns exec AG ip addr add 192.168.0.254/24 dev veth-AG-AC

    run ip netns exec AG ip link set br0-AG-NAVT.100 up
    run ip netns exec AG ip link set veth-AG-AC up
    run ip netns exec AG ip route add default via 172.26.2.254

    # todo remove
    # run ip netns exec AG ip neigh add 172.26.2.254 lladdr 02:03:04:05:06:fe dev br0-AG-NAVT.100

   # settings for B gateway
    run ip netns exec BG ip link set addr 02:03:04:05:06:22 dev br0-BG-NAVT.200
    run ip netns exec BG ip addr add 172.26.2.2/24 dev br0-BG-NAVT.200
    run ip netns exec BG ip addr add 192.168.0.254/24 dev veth-BG-BC

    run ip netns exec BG ip link set br0-BG-NAVT.200 up
    run ip netns exec BG ip link set veth-BG-BC up
    run ip netns exec BG ip route add default via 172.26.2.254

    # todo remove
    # run ip netns exec BG ip neigh add 172.26.2.254 lladdr 02:03:04:05:06:fe dev br0-BG-NAVT.200

   # settings for A Client
    run ip netns exec AC ip addr add 192.168.0.1/24 dev veth-AC-AG
    run ip netns exec AC ip link set veth-AC-AG up
    run ip netns exec AC ip route add default via 192.168.0.254

   # settings for B Client
    run ip netns exec BC ip addr add 192.168.0.1/24 dev veth-BC-BG
    run ip netns exec BC ip link set veth-BC-BG up
    run ip netns exec BC ip route add default via 192.168.0.254

    run ip netns exec BC sysctl -w net.ipv6.conf.all.disable_ipv6=1
    run ip netns exec BG sysctl -w net.ipv6.conf.all.disable_ipv6=1
    run ip netns exec AC sysctl -w net.ipv6.conf.all.disable_ipv6=1
    run ip netns exec AG sysctl -w net.ipv6.conf.all.disable_ipv6=1
    run ip netns exec NOC sysctl -w net.ipv6.conf.all.disable_ipv6=1
    run ip netns exec NERT sysctl -w net.ipv6.conf.all.disable_ipv6=1
    run sysctl -w net.ipv6.conf.all.disable_ipv6=1

    # # enable promiscuous mode
    # sudo ip link set enp0s8 promisc on
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
    run ip netns del NOC
    run ip netns del NERT

    run ip link del br0
    run ip link del br0-GW-NAVT
    run ip link del br0-NAVT-AG
    run ip link del br0-NAVT-BG

    run ip netns del AG
    run ip netns del AC

    run ip netns del BG
    run ip netns del BC

    run ip link del veth-AC-AG
    run ip link del veth-BC-BG
}

stop () {
    destroy_p4
    destroy_network
}

trap stop 0 1 2 3 13 14 15

# exec functions
create_network
connect_p4

status=0; $SHELL || status=$?
exit $status
