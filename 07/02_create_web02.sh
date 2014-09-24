function get_uuid () { cat - | grep " id " | awk '{print $4}'; }
export MY_DMZ_NET=`neutron net-show dmz-net | get_uuid`
export MY_APP_NET=`neutron net-show app-net | get_uuid`

nova boot --flavor standard.xsmall --image "centos-base" \
--key-name key-for-internal --user-data userdata_web.txt \
--security-groups sg-all-from-console,sg-web-from-internet,sg-all-from-app-net \
--availability-zone az1 \
--nic net-id=${MY_DMZ_NET} --nic net-id=${MY_APP_NET} \
web02
