
#ifndef __CONSTS__
#define __CONSTS__

#ifdef _V1_MODEL_P4_
typedef bit<9>  PortId_t; // ingress_port/egress_port in v1model
#endif /* _V1_MODEL_P4_ */

typedef bit<48> EthernetAddress;
typedef bit<32> IPv4Address;
typedef bit<128> IPv6Address;

typedef bit<16> EthernetType;
const EthernetType ETH_P_IPV4 = 16w0x0800;
const EthernetType ETH_P_ARP  = 16w0x0806;
const EthernetType ETH_P_VLAN = 16w0x8100;
const EthernetType ETH_P_IPV6 = 16w0x86dd;

typedef bit<12> vlan_id_t;
const vlan_id_t VLAN_DEFAULT = 12w0x0;

typedef bit<4> PortType;
const PortType PORT_UNASSIGNED = 4w0x0;
const PortType PORT_UNTAGGED   = 4w0x1;
const PortType PORT_TAGGED     = 4w0x2;

// https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
typedef bit<8> IPProtocol;
const IPProtocol IPPROTO_HOPOPT = 0; // IPv6 Hop-by-Hop Option
const IPProtocol IPPROTO_ICMP = 1;
const IPProtocol IPPROTO_IPV4 = 4;
const IPProtocol IPPROTO_TCP = 6;
const IPProtocol IPPROTO_UDP = 17;
const IPProtocol IPPROTO_IPV6 = 41;
const IPProtocol IPPROTO_ROUTE = 43; // Routing Header for IPv6
const IPProtocol IPPROTO_FRAG = 44; // Fragment Header for IPv6
const IPProtocol IPPROTO_GRE = 47;
const IPProtocol IPPROTO_ICMPv6 = 58; // ICMP for IPv6
const IPProtocol IPPROTO_NONXT = 59; // No Next Header for IPv6

// nexthop
typedef bit<32> nexthop_id_t;

// These definitions are derived from the numerical values of the enum
// named "PktInstanceType" in the p4lang/behavioral-model source file
// targets/simple_switch/simple_switch.h
// https://github.com/p4lang/behavioral-model/blob/master/targets/simple_switch/simple_switch.h#L126-L134

const bit<32> BMV2_V1MODEL_INSTANCE_TYPE_NORMAL        = 0;
const bit<32> BMV2_V1MODEL_INSTANCE_TYPE_INGRESS_CLONE = 1;
const bit<32> BMV2_V1MODEL_INSTANCE_TYPE_EGRESS_CLONE  = 2;
const bit<32> BMV2_V1MODEL_INSTANCE_TYPE_COALESCED     = 3;
const bit<32> BMV2_V1MODEL_INSTANCE_TYPE_RECIRC        = 4;
const bit<32> BMV2_V1MODEL_INSTANCE_TYPE_REPLICATION   = 5;
const bit<32> BMV2_V1MODEL_INSTANCE_TYPE_RESUBMIT      = 6;

#define IS_RESUBMITTED(st_md) (st_md.instance_type == BMV2_V1MODEL_INSTANCE_TYPE_RESUBMIT)
#define IS_RECIRCULATED(st_md) (st_md.instance_type == BMV2_V1MODEL_INSTANCE_TYPE_RECIRC)
#define IS_I2E_CLONE(st_md) (st_md.instance_type == BMV2_V1MODEL_INSTANCE_TYPE_INGRESS_CLONE)
#define IS_E2E_CLONE(st_md) (st_md.instance_type == BMV2_V1MODEL_INSTANCE_TYPE_EGRESS_CLONE)
#define IS_REPLICATED(st_md) (st_md.instance_type == BMV2_V1MODEL_INSTANCE_TYPE_REPLICATION)

const bit<32>  I2E_CLONE_SESSION_ID = 100; // send to CPU_PORT

#define CPU_PORT 255

#endif // __CONSTS__
