control PortMap(
        inout Header hdr,
        inout IngressMetadata ig_md,
        inout standard_metadata_t st_md) {

    action set_unassigned() {
        ig_md.port_type = PORT_UNASSIGNED;
    }
    action set_untagged(vlan_id_t vlan_id) {
        ig_md.port_type = PORT_UNTAGGED;
        ig_md.vlan_id = vlan_id;
    }
    action set_tagged() {
        ig_md.port_type = PORT_TAGGED;
    }
    table portmap {
        key = {
            st_md.ingress_port: exact;
        }
        actions = {
            set_unassigned;
            set_tagged;
            set_untagged;
        }
        const default_action = set_unassigned;
    }
    /* Port mapping rules for vlan.
     *  Note: tagged port should not accept non-tag packet and vice versa
     *  (header) x (port_type)
     *      none x none  : vlan_id = VLAN_DEFAULT(0)
     *      tag  x none  : drop => default port_type is untagged
     *      none x untag : vlan_id = config
     *      tag  x untag : drop?
     *      none x tag   : drop?
     *      tag  x tag   : vlan_id = hdr.vlan_tag.vid
    */
    action set_vlan_default() {
        ig_md.vlan_id = VLAN_DEFAULT;
    }
    action set_vlan_from_cfg() {
         // already asigned in table portmap. No operation required.
    }
    action set_vlan_from_hdr() {
        ig_md.vlan_id = hdr.vlan_tag.vid;
    }
    action err_vlan_invalid() {
        mark_to_drop(st_md);
    }
    table set_vlan_id {
        key = {
            hdr.vlan_tag.isValid(): exact;
            ig_md.port_type: exact;
        }
        actions = {
            set_vlan_default;
            set_vlan_from_cfg;
            set_vlan_from_hdr;
            err_vlan_invalid;
        }
        const entries = {
            (false, PORT_UNASSIGNED) : set_vlan_default();
            (true,  PORT_UNASSIGNED) : err_vlan_invalid();
            (false, PORT_UNTAGGED)  : set_vlan_from_cfg();
            (true,  PORT_UNTAGGED)  : err_vlan_invalid();
            (false, PORT_TAGGED)    : err_vlan_invalid();
            (true,  PORT_TAGGED)    : set_vlan_from_hdr();
        }
    }

    apply {
        portmap.apply();
        set_vlan_id.apply();

        if (hdr.vlan_tag.isValid()) {
            ig_md.vlan_pcp = hdr.vlan_tag.pcp;
            ig_md.vlan_dei = hdr.vlan_tag.dei;
            ig_md.etherType = hdr.vlan_tag.etherType;
        } else {
            ig_md.etherType = hdr.ether.etherType;
        }
    }
}

control PortMapEgress(
        inout Header hdr,
        inout UserMetadata u_md,
        inout standard_metadata_t st_md) {

    action vlan_tagged() {
        hdr.ether.etherType = ETH_P_VLAN;
        hdr.vlan_tag.setValid();
        hdr.vlan_tag.pcp = u_md.ig_md.vlan_pcp;
        hdr.vlan_tag.dei = u_md.ig_md.vlan_dei;
        hdr.vlan_tag.vid = u_md.ig_md.vlan_id;
        hdr.vlan_tag.etherType = u_md.ig_md.etherType;
    }
    action vlan_untagged() {
        hdr.ether.etherType = u_md.ig_md.etherType;
        hdr.vlan_tag.setInvalid();
    }
    action vlan_unassigned() {
        vlan_untagged();
    }

    table portmap_egress {
        key = {
            st_md.egress_port: exact;
        }
        actions = {
            vlan_unassigned;
            vlan_tagged;
            vlan_untagged;
        }
        const default_action = vlan_unassigned;
    }

    apply {
        portmap_egress.apply();
    }
}
