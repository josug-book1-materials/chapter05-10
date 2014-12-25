. ../lib/goodies.sh

function get_uuid () { cat - | grep " id " | awk '{print $4}'; }
export MY_DBS_VOL01=`cinder show dbs_vol01 |get_uuid`
echo $MY_DBS_VOL01

nova volume-attach dbs01 $MY_DBS_VOL01
cinder list

wait_for_cinder volume dbs_vol01 in-use
cinder list
