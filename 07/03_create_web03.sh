echo "#!/bin/bash" > userdata_web03.txt
echo "sh /root/sample-app/server-setup/web.init.sh start" >> userdata_web03.txt

function get_uuid () { cat - | grep " id " | awk '{print $4}'; }
export MY_DMZ_NET=`neutron net-show dmz-net | get_uuid`
export MY_APP_NET=`neutron net-show app-net | get_uuid`
nova boot --flavor standard.xsmall --image "web-base-v1.0" \
--key-name key-for-internal --user-data userdata_web03.txt \
--security-groups sg-all-from-console,sg-web-from-internet,sg-all-from-app-net \
--availability-zone az1 \
--nic net-id=${MY_DMZ_NET} --nic net-id=${MY_APP_NET} \
web03

