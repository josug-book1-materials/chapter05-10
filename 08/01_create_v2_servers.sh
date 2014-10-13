cd $HOME
source openrc
function get_uuid () { cat - | grep " id " | awk '{print $4}'; }
export MY_DMZ_NET=`neutron net-show dmz-net | get_uuid`
export MY_APP_NET=`neutron net-show app-net | get_uuid`
export MY_DBS_NET=`neutron net-show dbs-net | get_uuid`


nova boot --flavor standard.xsmall --image "centos-base" \
--key-name key-for-internal --user-data userdata_dbs.txt \
--security-groups sg-all-from-console,sg-all-from-dbs-net \
--availability-zone az1 --nic net-id=${MY_DMZ_NET} --nic net-id=${MY_DBS_NET} \
v2-dbs01


export MY_DBS_IP=`nova show v2-dbs01 |grep " dbs-net" |awk '{print $5}'`
nova boot --flavor standard.xsmall --image "centos-base" \
--key-name key-for-internal --user-data userdata_v2_app.txt \
--security-groups sg-all-from-console,sg-all-from-app-net,sg-all-from-dbs-net \
--availability-zone az1 \
--nic net-id=${MY_DMZ_NET} --nic net-id=${MY_APP_NET} --nic net-id=${MY_DBS_NET} \
--meta dbs_ip=${MY_DBS_IP} \
v2-app01


export MY_REST_IP=`nova show v2-app01 |grep " app-net" |awk '{print $5}'`
nova boot --flavor standard.xsmall --image "centos-base" \
--key-name key-for-internal --user-data userdata_v2_web.txt \
--security-groups sg-all-from-console,sg-web-from-internet,sg-all-from-app-net \
--availability-zone az1 \
--nic net-id=${MY_DMZ_NET} --nic net-id=${MY_APP_NET} \
--num-instances 4 \
--meta rest_ip=${MY_REST_IP} \
--meta keystone_url=${OS_AUTH_URL} \
--meta region_name=${OS_REGION_NAME} \
--meta tenant_name=${OS_TENANT_NAME} \
--meta user_name=${OS_USERNAME} \
--meta password=${OS_PASSWORD} \
v2-web


nova boot --flavor standard.xsmall --image "centos-base" \
--key-name key-for-internal --user-data userdata_lbs.txt \
--security-groups sg-all-from-console,sg-web-from-internet \
--availability-zone az1 \
--nic net-id=${MY_DMZ_NET} \
v2-lbs01

