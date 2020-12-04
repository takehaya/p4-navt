control Navt(
    inout EthernetAddress ether_src_addr,
    inout EthernetAddress ether_dst_addr,
    inout IPv4Address ip_src_addr,
    inout IPv4Address ip_dst_addr,
    inout IngressMetadata ig_md,
    inout standard_metadata_t st_md)
    () {
    apply {
        if (ig_md.etherType == ETH_P_IPV4) {
            // dst is 192.168.0.0/16 is not work
            if (ip_dst_addr[8:0] == 10 && ip_dst_addr[16:9] == 168){
                mark_to_drop(st_md);
                return;
            }

            if (ip_dst_addr[31:24] == 10 && 1 <= ip_dst_addr[31:24] && ip_dst_addr[31:24] <= 15){
                if (ip_src_addr[31:24] == 10 && 1 <= ip_src_addr[31:24] && ip_src_addr[31:24] <= 15) {
                    return;
                }
                // to external nat
                ip_dst_addr[31:24] = 192;

                // mean is `ig_md.vlan_id = ip_dst_addr[23:16] * 100;`
                ig_md.vlan_id = (bit<12>)((ip_dst_addr[23:16]<<5)+(ip_dst_addr[23:16]<<6)+(ip_dst_addr[23:16]<<2));
                ip_dst_addr[23:16] = 168;
                if (ig_md.vlan_id == 100){
                    ether_dst_addr = 0x020304050611;
                    ether_src_addr = 0x0203040506fe;
                }else if(ig_md.vlan_id == 200){
                    ether_dst_addr = 0x020304050622;
                    ether_src_addr = 0x0203040506fe;
                }
                ig_md.to_tagging = 1;
            } else {
                // to internal nat
                ip_src_addr[31:24] = 10;
                if (ig_md.vlan_id == 100){
                    ip_src_addr[23:16] = 1;
                }else if(ig_md.vlan_id == 200){
                    ip_src_addr[23:16] = 2;
                }
                // mean is `ip_src_addr[23:16] = (bit<8>)(ig_md.vlan_id/100);`
                // ip_src_addr[23:16] = (bit<8>)((ig_md.vlan_id>>4)+(ig_md.vlan_id>>5)+(ig_md.vlan_id>>7));
                // ip_src_addr[23:16] = (bit<8>)(ig_md.vlan_id>>4);
                ether_dst_addr = 0x020304050601;
                ether_src_addr = 0x0203040506fe;
                ig_md.vlan_id = 0; // port vlan
                ig_md.to_tagging = 0;
            }
        }
    }
}
