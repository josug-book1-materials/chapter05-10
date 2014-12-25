#!/bin/bash

cd $(dirname $0)

OPENRC=$HOME/openrc
ENVFILE=../lib/env.sh
GOODIESFILE=../lib/goodies.sh
WORK_DIR=$HOME/work_chapter

source $OPENRC
source $ENVFILE
source $GOODIESFILE

mkdir -p $WORK_DIR
cp -v userdata_v2_app.txt $WORK_DIR
cp -v userdata_v2_web.txt $WORK_DIR

cd $WORK_DIR

export MY_DMZ_NET=`neutron net-show dmz-net | get_uuid`
export MY_APP_NET=`neutron net-show app-net | get_uuid`
export MY_DBS_NET=`neutron net-show dbs-net | get_uuid`

nova boot --flavor standard.xsmall --image "centos-base" \
  --key-name key-for-internal --user-data userdata_dbs.txt \
  --security-groups sg-all-from-console,sg-all-from-dbs-net \
  --availability-zone az1 --nic net-id=${MY_DMZ_NET} --nic net-id=${MY_DBS_NET} \
v2-dbs01

wait_instance v2-dbs01 dmz-net

export MY_DBS_IP=`nova show v2-dbs01 |grep " dbs-net" |awk '{print $5}'`
nova boot --flavor standard.xsmall --image "centos-base" \
  --key-name key-for-internal --user-data userdata_v2_app.txt \
  --security-groups sg-all-from-console,sg-all-from-app-net,sg-all-from-dbs-net \
  --availability-zone az1 \
  --nic net-id=${MY_DMZ_NET} --nic net-id=${MY_APP_NET} --nic net-id=${MY_DBS_NET} \
  --meta dbs_ip=${MY_DBS_IP} \
v2-app01

wait_instance v2-app01 dmz-net

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

for server in `nova list --field name | grep v2-web | awk '{print $4}'`; do
  wait_instance $server dmz-net
done

nova boot --flavor standard.xsmall --image "centos-base" \
  --key-name key-for-internal --user-data userdata_lbs.txt \
  --security-groups sg-all-from-console,sg-web-from-internet \
  --availability-zone az1 \
  --nic net-id=${MY_DMZ_NET} \
v2-lbs01

wait_instance v2-lbs01 dmz-net
