. ../lib/goodies.sh

function get_uuid () { cat - | grep " id " | awk '{print $4}'; }
export MY_DBS_VOL01=`cinder show dbs_vol01 |get_uuid`
export MY_DBS_VOL01_SNAP001=`cinder snapshot-show dbs_vol01-snap001 | get_uuid`

nova volume-detach dbs01 $MY_DBS_VOL01
cinder list

wait_for_cinder volume $MY_DBS_VOL01 available
cinder list

cinder snapshot-delete $MY_DBS_VOL01_SNAP001
cinder snapshot-list

wait_for_cinder_delete snapshot $MY_DBS_VOL01_SNAP001
cinder snapshot-list

cinder delete $MY_DBS_VOL01
cinder list

wait_for_cinder_delete volume $MY_DBS_VOL01
cinder list
