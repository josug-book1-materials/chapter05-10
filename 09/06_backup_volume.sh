. ../lib/goodies.sh

function get_uuid () { cat - | grep " id " | awk '{print $4}'; }
export MY_DBS_VOL01_RES=`cinder show dbs_vol01_res |get_uuid`

nova volume-detach dbs01 $MY_DBS_VOL01_RES
cinder list

wait_for_cinder volume $MY_DBS_VOL01_RES available
cinder list

cinder backup-create --display-name dbs_vol01_res-backup01 $MY_DBS_VOL01_RES
export MY_DBS_VOL01_RES_BK01=`cinder backup-list | grep dbs_vol01_res-backup01 | awk '{print $2}'`
cinder backup-show $MY_DBS_VOL01_RES_BK01
cinder backup-list

wait_for_cinder backup $MY_DBS_VOL01_RES_BK01 available
cinder backup-list
swift stat volumebackups

nova volume-attach dbs01 $MY_DBS_VOL01_RES
cinder list

wait_for_cinder volume $MY_DBS_VOL01_RES in-use
cinder list
