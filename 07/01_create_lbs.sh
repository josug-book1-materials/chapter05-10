function get_uuid () { cat - | grep " id " | awk '{print $4}'; }
export MY_DMZ_NET=`neutron net-show dmz-net | get_uuid`
export MY_APP_NET=`neutron net-show app-net | get_uuid`
export MY_DBS_NET=`neutron net-show dbs-net | get_uuid`

nova boot --flavor standard.xsmall --image "centos-base" \
--key-name key-for-internal --user-data userdata_lbs.txt \
--security-groups sg-all-from-console,sg-web-from-internet \
--availability-zone az1 \
--nic net-id=${MY_DMZ_NET} \
lbs01

