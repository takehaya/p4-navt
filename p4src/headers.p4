
#ifndef _HEADERS_
#define _HEADERS_

header Ethernet_h {
    EthernetAddress dstAddr;
    EthernetAddress srcAddr;
    EthernetType etherType;
}

header VlanTag_h {
    bit<3> pcp; // Priority code point
    bit<1> dei; // Drop eligible inicator (formally CFI)
    vlan_id_t vid; // VLAN identifier
    EthernetType etherType;
}

header IPv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3> flags;
    bit<13> fragOffset;
    bit<8> ttl;
    IPProtocol protocol;
    bit<16> hdrChecksum;
    IPv4Address srcAddr;
    IPv4Address dstAddr;
}

header IPv6_h {
    bit<4> version;
    bit<8> trafficClass;
    bit<20> flowLabel;
    bit<16> payloadLen;
    bit<8> nextHdr;
    bit<8> hopLimit;
    IPv6Address srcAddr;
    IPv6Address dstAddr;
}

header TCP_h {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seq;
    bit<32> ack;
    bit<4> dataOffset;
    bit<4> res;
    bit<8> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

header UDP_h {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> length;
    bit<16> checksum;
}

header ICMP_h {
    bit<8> type;
    bit<8> code;
    bit<16> hdrChecksum;
    bit<32> restOfHeader;
    // restOfHeader vary based on the ICMP type and code
    // implement correctly when supporting ICMP
}

@controller_header("packet_out")
header PacketOutHeader {
    vlan_id_t vlan_id;//12
    bit<4> padding;
}

@controller_header("packet_in")
header PacketInHeader {
    bit<32> vrf; // not use
    vlan_id_t vlan_id;//12
    bit<1> is_clone;
    bit<3> padding;
}

#include "structs.p4" // include structs including parsed headers

#endif // _HEADERS_
