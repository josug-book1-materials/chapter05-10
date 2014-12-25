. ../lib/goodies.sh

function get_uuid () { cat - | grep " id " | awk '{print $4}'; }

cinder create --display-name dbs_vol02 --availability-zone az1 10
export MY_DBS_VOL02=`cinder show dbs_vol02 |get_uuid`

export MY_DBS_VOL01_RES_BK01=`cinder backup-list | grep dbs_vol01_res-backup01 | awk '{print $2}'`
cinder backup-restore --volume-id $MY_DBS_VOL02 $MY_DBS_VOL01_RES_BK01
cinder list

wait_for_cinder volume $MY_DBS_VOL02 available
cinder list
cinder backup-list

# Rename to dbs_vol02 again to avoid name duplication in Juno
cinder rename $MY_DBS_VOL02 dbs_vol02
cinder list
