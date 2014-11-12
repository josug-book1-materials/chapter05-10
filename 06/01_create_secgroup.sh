neutron security-group-create sg-web-from-internet
neutron security-group-create sg-all-from-app-net
neutron security-group-create sg-all-from-dbs-net
neutron security-group-create sg-all-from-console

neutron security-group-rule-create --ethertype IPv4 --protocol tcp \
--port-range-min 80 --port-range-max 80 \
--remote-ip-prefix 0.0.0.0/0 sg-web-from-internet
neutron security-group-rule-create --ethertype IPv4 --protocol tcp \
--port-range-min 443 --port-range-max 443 \
--remote-ip-prefix 0.0.0.0/0 sg-web-from-internet

neutron security-group-rule-create --ethertype IPv4 --protocol tcp \
--port-range-min 1 --port-range-max 65535 \
--remote-ip-prefix 172.16.10.0/24 sg-all-from-app-net
neutron security-group-rule-create --ethertype IPv4 --protocol icmp \
--remote-ip-prefix 172.16.10.0/24 sg-all-from-app-net

neutron security-group-rule-create --ethertype IPv4 --protocol tcp \
--port-range-min 1 --port-range-max 65535 \
--remote-ip-prefix 172.16.20.0/24 sg-all-from-dbs-net
neutron security-group-rule-create --ethertype IPv4 --protocol icmp \
--remote-ip-prefix 172.16.20.0/24 sg-all-from-dbs-net

neutron security-group-rule-create --ethertype IPv4 --protocol tcp \
--port-range-min 1 --port-range-max 65535 \
--remote-ip-prefix 10.0.0.0/24 sg-all-from-console
neutron security-group-rule-create --ethertype IPv4 --protocol icmp \
--remote-ip-prefix 10.0.0.0/24 sg-all-from-console

