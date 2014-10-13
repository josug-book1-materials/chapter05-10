function get_uuid () { cat - | grep " id " | awk '{print $4}'; }
export MY_DMZ_NET=`neutron net-show dmz-net | get_uuid`
export MY_DBS_NET=`neutron net-show dbs-net | get_uuid`

nova boot --flavor standard.xsmall --image "centos-base" \
--key-name key-for-internal --user-data userdata_dbs.txt \
--security-groups sg-all-from-console,sg-all-from-dbs-net \
--availability-zone az2 \
--nic net-id=${MY_DMZ_NET} --nic net-id=${MY_DBS_NET} \
az2-dbs01


cinder create --display-name az2_dbs_vol01 --availability-zone az2 10

