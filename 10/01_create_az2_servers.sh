function get_uuid () { cat - | grep " id " | awk '{print $4}'; }
export MY_DMZ_NET=`neutron net-show dmz-net | get_uuid`
export MY_APP_NET=`neutron net-show app-net | get_uuid`
export MY_DBS_NET=`neutron net-show dbs-net | get_uuid`


nova boot --flavor standard.xsmall --image "centos-base" \
--key-name key-for-internal --user-data userdata_app.txt \
--security-groups sg-all-from-console,sg-all-from-app-net,sg-all-from-dbs-net \
--availability-zone az2 \
--nic net-id=${MY_DMZ_NET} --nic net-id=${MY_APP_NET} --nic net-id=${MY_DBS_NET} \
az2-app01


nova boot --flavor standard.xsmall --image "centos-base" \
--key-name key-for-internal --user-data userdata_web.txt \
--security-groups sg-all-from-console,sg-web-from-internet,sg-all-from-app-net \
--availability-zone az2 \
--num-instances 2 \
--nic net-id=${MY_DMZ_NET} --nic net-id=${MY_APP_NET} \
az2-web


nova boot --flavor standard.xsmall --image "centos-base" \
--key-name key-for-internal --user-data userdata_lbs.txt \
--security-groups sg-all-from-console,sg-web-from-internet \
--availability-zone az2 \
--nic net-id=${MY_DMZ_NET} \
az2-lbs01


