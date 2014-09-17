nova boot --flavor standard.xsmall --image "centos-base" \
--key-name key-for-internal --user-data userdata_web.txt \
--security-groups sg-all-from-console,sg-web-from-internet,sg-all-from-app-net \
--availability-zone az1 \
--nic net-id=${MY_DMZ_NET} --nic net-id=${MY_APP_NET} \
web01

nova boot --flavor standard.xsmall --image "centos-base" \
--key-name key-for-internal --user-data userdata_app.txt \
--security-groups sg-all-from-console,sg-all-from-app-net,sg-all-from-dbs-net \
--availability-zone az1 \
--nic net-id=${MY_DMZ_NET} --nic net-id=${MY_APP_NET} --nic net-id=${MY_DBS_NET} \
app01

nova boot --flavor standard.xsmall --image "centos-base" \
--key-name key-for-internal --user-data userdata_dbs.txt \
--security-groups sg-all-from-console,sg-all-from-dbs-net \
--availability-zone az1 \
--nic net-id=${MY_DMZ_NET} --nic net-id=${MY_DBS_NET} \
dbs01

