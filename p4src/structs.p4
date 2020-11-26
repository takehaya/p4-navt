#ifndef _STRUCTS_
#define _STRUCTS_

struct Header {
    Ethernet_h ether;
    VlanTag_h vlan_tag;
    IPv6_h ipv6;
    IPv4_h ipv4;
    ICMP_h icmp;
    TCP_h tcp;
    UDP_h udp;
}

struct MacLearnDigest_t {
    EthernetAddress srcAddr;
    PortId_t        ingress_port;
    vlan_id_t       vlan_id;
}

// Generic ingress metadata (architecture independent)
struct IngressMetadata {
    bit<1> is_tagged;
    bit<1> flood;
    bit<3> vlan_pcp;
    bit<1> vlan_dei;
    vlan_id_t vlan_id; // bit<12>
    PortType port_type;
    EthernetType etherType;
    nexthop_id_t nexthop_id;
}
// Generic egress metadata (architecture independent)
struct EgressMetadata {
    // none defined yet
}
// User Metadata (for v1model)
struct UserMetadata {
    IngressMetadata ig_md;
    EgressMetadata eg_md;
}

#endif // _STRUCTS_
