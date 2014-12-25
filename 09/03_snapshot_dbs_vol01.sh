. ../lib/goodies.sh

function get_uuid () { cat - | grep " id " | awk '{print $4}'; }
export MY_DBS_VOL01=`cinder show dbs_vol01 |get_uuid`

nova volume-detach dbs01 $MY_DBS_VOL01
cinder list

wait_for_cinder volume dbs_vol01 available
cinder list

cinder snapshot-create --display-name dbs_vol01-snap001 $MY_DBS_VOL01
cinder snapshot-list

wait_for_cinder snapshot dbs_vol01-snap001 available
cinder snapshot-list

nova volume-attach dbs01 $MY_DBS_VOL01
cinder list

wait_for_cinder volume dbs_vol01 in-use
cinder list
