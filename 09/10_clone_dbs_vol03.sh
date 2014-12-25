. ../lib/goodies.sh

function get_uuid () { cat - | grep " id " | awk '{print $4}'; }
export MY_DBS_VOL02=`cinder show dbs_vol02 |get_uuid`

cinder create --source-volid $MY_DBS_VOL02 --display-name dbs_vol03 --availability-zone az1 10
export MY_DBS_VOL03=`cinder show dbs_vol03 |get_uuid`
wait_for_cinder volume $MY_DBS_VOL03 available
cinder list

nova volume-attach dbs01 $MY_DBS_VOL02
cinder list
wait_for_cinder volume $MY_DBS_VOL02 in-use
cinder list

nova volume-attach dbs01 $MY_DBS_VOL03
cinder list
wait_for_cinder volume $MY_DBS_VOL03 in-use
cinder list
