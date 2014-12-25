. ../lib/goodies.sh

function get_uuid () { cat - | grep " id " | awk '{print $4}'; }
export MY_DBS_VOL01_RES=`cinder show dbs_vol01_res |get_uuid`
export MY_DBS_VOL01_RES_BK01=`cinder backup-list | grep dbs_vol01_res-backup01 | awk '{print $2}'`
export MY_DBS_VOL02=`cinder show dbs_vol02 |get_uuid`

nova volume-detach dbs01 $MY_DBS_VOL01_RES
cinder list
wait_for_cinder volume $MY_DBS_VOL01_RES available
cinder list

cinder backup-restore --volume-id $MY_DBS_VOL01_RES $MY_DBS_VOL01_RES_BK01
cinder backup-list
cinder list
wait_for_cinder volume $MY_DBS_VOL01_RES available
cinder list

nova volume-attach dbs01 $MY_DBS_VOL01_RES
cinder list
wait_for_cinder volume $MY_DBS_VOL01_RES in-use
cinder list

nova volume-attach dbs01 $MY_DBS_VOL02
cinder list
wait_for_cinder volume $MY_DBS_VOL02 in-use
cinder list
