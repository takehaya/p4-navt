#include <core.p4>
#include <v1model.p4>
#include "consts.p4"
#include "headers.p4"
#include "parser.p4"
#include "port.p4"
#include "portfwd.p4"
#include "l2.p4"

// CONTROL: INGRESS -------------------------------------------------------

control SwitchIngress(
            inout Header hdr,
            inout UserMetadata user_md,
            inout standard_metadata_t st_md) {

    PortMap() portmap;
    L2Fwd(1024) l2fwd;
    PortFwd() portfwd;

    apply {
        mark_to_drop(st_md);
        portmap.apply(hdr, user_md.ig_md, st_md); // set vlan_id from port_type

        l2fwd.apply(hdr.ether.dstAddr, hdr.ether.srcAddr, user_md.ig_md, st_md);

        portfwd.apply(st_md.ingress_port, st_md.egress_spec, st_md.mcast_grp);
    }
}

// CONTROL: EGRESS --------------------------------------------------------

control SwitchEgress(
            inout Header hdr,
            inout UserMetadata user_md,
            inout standard_metadata_t st_md) {

    action drop() { // indirection to support mltiple platform
        mark_to_drop(st_md);
    }

    PortMapEgress() portmap_egress;

    apply {
        // drop flood packet going back to incoming port
        if(st_md.ingress_port == st_md.egress_port && user_md.ig_md.flood == 1) {
            drop();
        }
        portmap_egress.apply(hdr, user_md, st_md);
    }
}

// CONTROL: CHECKSUM ------------------------------------------------------

control NoSwitchVerifyChecksum(
            inout Header hdr,
            inout UserMetadata user_md) {
    // dummy control to skip checkum
    apply { }
}
control SwitchVerifyChecksum(
            inout Header hdr,
            inout UserMetadata user_md) {
    apply {
        verify_checksum(hdr.ipv4.isValid() && hdr.ipv4.ihl == 5,
            { hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.diffserv,
                hdr.ipv4.totalLen,
                hdr.ipv4.identification,
                hdr.ipv4.flags,
                hdr.ipv4.fragOffset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.srcAddr,
                hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
    }
}
control NoSwitchComputeChecksum(
            inout Header hdr,
            inout UserMetadata user_md) {
    // dummy control to skip checkum
    apply { }
}
control SwitchComputeChecksum(
            inout Header hdr,
            inout UserMetadata user_md) {
    apply {
        update_checksum(hdr.ipv4.isValid() && hdr.ipv4.ihl == 5,
            { hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.diffserv,
                hdr.ipv4.totalLen,
                hdr.ipv4.identification,
                hdr.ipv4.flags,
                hdr.ipv4.fragOffset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.srcAddr,
                hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
    }
}


V1Switch(SwitchParser(),
         //SwitchVerifyChecksum(),
         NoSwitchVerifyChecksum(),
         SwitchIngress(),
         SwitchEgress(),
         //SwitchComputeChecksum(),
         NoSwitchComputeChecksum(),
         SwitchDeparser()
) main;
