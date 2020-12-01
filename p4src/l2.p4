control L2Fwd(
    in EthernetAddress ether_dst_addr,
    in EthernetAddress ether_src_addr,
    inout IngressMetadata ig_md,
    inout standard_metadata_t st_md)
    (bit<32> table_size_dmac) {

    action smac_miss() {
        // #ifdef _V1_MODEL_P4_
        // digest<MacLearnDigest_t>(1,{ether_src_addr, st_md.ingress_port});
        // #endif /* _V1_MODEL_P4_ */
    }
    action smac_hit() {
        NoAction();
    }
    table smac {
        key = {
            ether_src_addr : exact;
            st_md.ingress_port : exact;
        }
        actions = {
            smac_miss;
            smac_hit;
        }
        const default_action = smac_miss;
    }
    action dmac_miss() {
        ig_md.flood = 1;
    }
    action dmac_hit(PortId_t port) {
        st_md.egress_spec = port;
    }

    table dmac {
        key = {
            ether_dst_addr : exact;
        }
        actions = {
            dmac_miss;
            dmac_hit;
        }
        const default_action = dmac_miss();
        size = table_size_dmac;
    }

    apply {
        smac.apply();
        dmac.apply();
    }
}
