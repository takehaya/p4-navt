control PortMap(
        inout Header hdr,
        inout IngressMetadata ig_md,
        inout standard_metadata_t st_md) {

    apply {
        if (hdr.vlan_tag.isValid()) {
            ig_md.vlan_pcp = hdr.vlan_tag.pcp;
            ig_md.vlan_dei = hdr.vlan_tag.dei;
            ig_md.vlan_id = hdr.vlan_tag.vid;
            ig_md.etherType = hdr.vlan_tag.etherType;
        } else {
            ig_md.etherType = hdr.ether.etherType;
        }
    }
}

control PortMapEgress(
        inout Header hdr,
        inout UserMetadata user_md,
        inout standard_metadata_t st_md) {

    action vlan_tagged() {
        hdr.ether.etherType = ETH_P_VLAN;
        hdr.vlan_tag.setValid();
        hdr.vlan_tag.pcp = user_md.ig_md.vlan_pcp;
        hdr.vlan_tag.dei = user_md.ig_md.vlan_dei;
        hdr.vlan_tag.vid = user_md.ig_md.vlan_id;
        hdr.vlan_tag.etherType = user_md.ig_md.etherType;
    }
    action vlan_untagged() {
        hdr.ether.etherType = user_md.ig_md.etherType;
        hdr.vlan_tag.setInvalid();
    }
    action vlan_unassigned() {
        vlan_untagged();
    }

    apply {
        if (user_md.ig_md.to_tagging == 1){
            vlan_tagged();
        }else{
            vlan_untagged();
        }
    }
}
