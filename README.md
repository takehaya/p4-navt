# p4-navt
NAVT(Network Address Vlan Translation) write by p4-16.
e.g. VID:100, 192.168.0.1(inside) &lt;=> 10.1.0.1 (outside)

## Build
```
# Please go to the top directory
p4c --std p4_16 -b bmv2 --p4runtime-files build.bmv2/switch.p4.p4info.txt -o build.bmv2 p4src/switch.p4
```

## Run
```
sudo ./script/playground.sh
```
