# port 1 untag vlan 100, 200
# port 2~3 tag vlan 100
# port 4~5 tag vlan 200
# table_add portmap set_unassigned 1 =>
# table_add portmap set_tagged 2 =>
# table_add portmap set_tagged 3 =>
# table_add portmap set_tagged 4 =>
# table_add portmap set_tagged 5 =>

# table_add portmap_egress set_unassigned 1 =>
# table_add portmap_egress vlan_tagged 2 =>
# table_add portmap_egress vlan_tagged 3 =>
# table_add portmap_egress vlan_tagged 4 =>
# table_add portmap_egress vlan_tagged 5 =>

# tagged
# mc_node_create 65000 2 3 4
# mc_node_create 65000 5 6

# mc_node_create 65000 2 3 4
# mc_node_create 65000 5 6

# untagged
# mc_node_create 65001 1
# mc_node_create 65001 1

# mc_mgrp_create 100
# mc_mgrp_create 200

# mc_node_associate 100 0
# mc_node_associate 100 1
# mc_node_associate 100 4

# mc_node_associate 200 2
# mc_node_associate 200 3
# mc_node_associate 200 5

table_add dmac dmac_hit 0x020304050601 0 => 1
table_add dmac dmac_hit 0x020304050611 100 => 2
table_add dmac dmac_hit 0x020304050622 200 => 2
# table_add dmac dmac_hit 0x020304050612 100 => 3
# table_add dmac dmac_hit 0x020304050621 200 => 4
# table_add dmac dmac_hit 0x020304050622 200 => 5
