. ../lib/goodies.sh

function get_uuid () { cat - | grep " id " | awk '{print $4}'; }
export MY_DBS_VOL02=`cinder show dbs_vol02 |get_uuid`

nova volume-detach dbs01 $MY_DBS_VOL02
cinder list
wait_for_cinder volume $MY_DBS_VOL02 available
cinder list
