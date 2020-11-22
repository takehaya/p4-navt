control Navt(
    in IPv4Address ip_src_addr,
    in IPv4Address ip_dst_addr,
    inout IngressMetadata ig_md,
    inout standard_metadata_t st_md)
    () {
    apply {
        if ig_md.etherType == ETH_P_IPV4 {
            // 192.168.0.0/16 is not work
            if ip_dst_addr[8:0] == 10 && ip_dst_addr[16:9] == 168{
                return;
            }
            if ip_dst_addr[8:0] == 10 && 1 <= ip_dst_addr[8:0] && ip_dst_addr[8:0] <= 15{
                if ip_src_addr[8:0] == 10 && 1 <= ip_src_addr[8:0] && ip_src_addr[8:0] <= 15{
                    return;
                }
                // to external nat
                ip_src_addr[8:0] = 10;
                ip_src_addr[16:9] = 168;
            }else{
                // to internal nat
                ip_src_addr[8:0] = 10;
                ip_src_addr[16:9] = ig_md.vlan_id/100;
            }
        }
    }
}
