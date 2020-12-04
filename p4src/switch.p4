#include <core.p4>
#include <v1model.p4>
#include "consts.p4"
#include "headers.p4"
#include "parser.p4"
#include "port.p4"
#include "portfwd.p4"
#include "l2.p4"
#include "navt.p4"

// CONTROL: INGRESS -------------------------------------------------------

control SwitchIngress(
            inout Header hdr,
            inout UserMetadata user_md,
            inout standard_metadata_t st_md) {

    PortMap() portmap;
    L2Fwd(1024) l2fwd;
    Navt() navt;
    action send_to_host() {
        clone3(CloneType.I2E, I2E_CLONE_SESSION_ID, {st_md, user_md});
    }

    action localmac_hit() {
        NoAction();
    }
    table localmac {
        key = {
            hdr.ether.dstAddr: exact;
        }
        actions = {
            localmac_hit;
            send_to_host;
        }
    }

    apply {
        if (st_md.ingress_port == CPU_PORT) {
            user_md.ig_md.vlan_id = hdr.packet_out.vlan_id;
            if (hdr.packet_out.vlan_id != 0){
                user_md.ig_md.to_tagging = 1;
            }
            hdr.packet_out.setInvalid();
        }

        mark_to_drop(st_md);
        portmap.apply(hdr, user_md.ig_md, st_md); // set vlan_id from port_type

        if (st_md.ingress_port != CPU_PORT) {
            switch (localmac.apply().action_run) {
                localmac_hit: {
                    navt.apply(
                        hdr.ether.srcAddr,
                        hdr.ether.dstAddr,
                        hdr.ipv4.srcAddr,
                        hdr.ipv4.dstAddr,
                        user_md.ig_md,
                        st_md
                    );
                }
            }
        }
        if (st_md.egress_spec != CPU_PORT) {
            l2fwd.apply(hdr.ether.dstAddr, hdr.ether.srcAddr, user_md.ig_md, st_md);
        }
    }
}

// CONTROL: EGRESS --------------------------------------------------------

control SwitchEgress(
            inout Header hdr,
            inout UserMetadata user_md,
            inout standard_metadata_t st_md) {

    action drop() {
        mark_to_drop(st_md);
    }

    PortMapEgress() portmap_egress;

    apply {
        if(st_md.egress_port == CPU_PORT){
            hdr.packet_in.setValid();
            hdr.packet_in.vlan_id = user_md.ig_md.vlan_id;
            hdr.ether.etherType = user_md.ig_md.etherType;
            if (IS_I2E_CLONE(st_md) || IS_E2E_CLONE(st_md)) {
                hdr.packet_in.is_clone = 1;
            } else {
                hdr.packet_in.is_clone = 0;
            }
            // vtap is unable to receive vlan packets.
            // So i do decap.
            user_md.ig_md.to_tagging = 0;
        }

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
         SwitchComputeChecksum(),
        //  NoSwitchComputeChecksum(),
         SwitchDeparser()
) main;
