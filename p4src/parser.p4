
#ifndef _PARSER_
#define _PARSER_

parser SwitchParser(
            packet_in pkt,
            out Header hdr,
            inout UserMetadata user_md,
            inout standard_metadata_t st_md) {

    state start {
        transition select(st_md.ingress_port) {
            CPU_PORT: parse_packet_out;
            default: parse_ethernet;
        }
    }
    state parse_packet_out {
        pkt.extract(hdr.packet_out);
        transition parse_ethernet;
    }
    state parse_ethernet {
        pkt.extract(hdr.ether);
        transition select(hdr.ether.etherType) {
            ETH_P_VLAN : parse_vlan;
            ETH_P_IPV4 : parse_ipv4;
            ETH_P_IPV6 : parse_ipv6;
            default : accept;
        }
    }
    state parse_vlan {
        pkt.extract(hdr.vlan_tag);
        transition select(hdr.vlan_tag.etherType) {
            ETH_P_IPV4 : parse_ipv4;
            ETH_P_IPV6 : parse_ipv6;
            default : accept;
        }
    }
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            IPPROTO_TCP : parse_tcp;
            IPPROTO_UDP : parse_udp;
            default : accept;
        }
    }
    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.nextHdr) {
            IPPROTO_TCP : parse_tcp;
            IPPROTO_UDP : parse_udp;
            default : accept;
        }
    }
    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }
    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dstPort) {
            default: accept;
        }
    }
}

control SwitchDeparser(
            packet_out pkt,
            in Header hdr) {

    apply {
        pkt.emit(hdr.packet_in);
        pkt.emit(hdr.ether);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.icmp);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.udp);
    }
}

#endif // _PARSER_
