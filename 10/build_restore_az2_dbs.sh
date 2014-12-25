. ../lib/goodies.sh

function get_uuid () { cat - | grep " id " | awk '{print $4}'; }
export MY_DMZ_NET=`neutron net-show dmz-net | get_uuid`
export MY_DBS_NET=`neutron net-show dbs-net | get_uuid`

nova boot --flavor standard.xsmall --image "centos-base" \
--key-name key-for-internal --user-data userdata_dbs.txt \
--security-groups sg-all-from-console,sg-all-from-dbs-net \
--availability-zone az2 \
--nic net-id=${MY_DMZ_NET} --nic net-id=${MY_DBS_NET} \
az2-dbs01

wait_instance az2-dbs01 dmz-net

AZ2_DBS01_IP=`get_instane_ip az2-dbs01 dmz-net`

wait_ping_resp $AZ2_DBS01_IP

MYSQL_IP=`get_instane_ip az2-dbs01 dbs-net`



cinder create --display-name az2_dbs_vol01 --availability-zone az2 10
export MY_AZ2_DBS_VOL01=`cinder show az2_dbs_vol01 | get_uuid`
cinder list
wait_for_cinder volume $MY_AZ2_DBS_VOL01 available
cinder list

cinder backup-list
export MY_DBS_VOL01_RES_BK01=`cinder backup-list |grep dbs_vol01_res-backup01 | awk '{print $2}'`
cinder backup-restore --volume-id $MY_AZ2_DBS_VOL01 $MY_DBS_VOL01_RES_BK01
cinder list
wait_for_cinder volume $MY_AZ2_DBS_VOL01 available
cinder list
cinder backup-list
cinder rename $MY_AZ2_DBS_VOL01 az2_dbs_vol01

nova volume-attach az2-dbs01 $MY_AZ2_DBS_VOL01
wait_for_cinder volume $MY_AZ2_DBS_VOL01 in-use
cinder list

echo "### az2_dbs_vol01 ($AZ2_DBS01_IP) is now prepared."
