function get_uuid () { cat - | grep " id " | awk '{print $4}'; }
export MY_DMZ_NET=`neutron net-show dmz-net | get_uuid`
export MY_APP_NET=`neutron net-show app-net | get_uuid`
export MY_REST_IP=`nova show app01 |grep " app-net" |awk '{print $5}'`

nova boot --flavor standard.xsmall --image "centos-base" \
--key-name key-for-internal --user-data userdata_web_auto_setting.txt \
--security-groups sg-all-from-console,sg-web-from-internet,sg-all-from-app-net \
--availability-zone az1 \
--nic net-id=${MY_DMZ_NET} --nic net-id=${MY_APP_NET} \
--meta rest_ip=${MY_REST_IP} \
web04
