. ../lib/goodies.sh

function get_uuid () { cat - | grep " id " | awk '{print $4}'; }
export MY_DBS_VOL01_SNAP001=`cinder snapshot-show dbs_vol01-snap001 |get_uuid`
echo $MY_DBS_VOL01_SNAP001

cinder create --snapshot-id $MY_DBS_VOL01_SNAP001 \
    --display-name dbs_vol01_res --availability-zone az1 10
export MY_DBS_VOL01_RES=`cinder show dbs_vol01_res |get_uuid`
echo $MY_DBS_VOL01_RES
cinder list

wait_for_cinder volume $MY_DBS_VOL01_RES available
cinder list

nova volume-attach dbs01 $MY_DBS_VOL01_RES
cinder list

wait_for_cinder volume $MY_DBS_VOL01_RES in-use
cinder list
