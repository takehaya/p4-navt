control PortFwd(
        in PortId_t in_port,
        inout PortId_t egress_port,
        inout bit<16> mcast_grp) { // st_md.mcast_grp (v1model.p4)

    action set_egress_port(PortId_t port) {
        egress_port = port;
        // cancel multicast when portfwd rule hits
        // This is v1model(bmv2) specific so should be refactored
        mcast_grp = 0;
    }

    table portfwd {
        key = {
            in_port: exact; // ingress phy port
        }
        actions = {
            set_egress_port;
        }
    }

    apply {
        portfwd.apply();
    }
}
