. ../lib/goodies.sh

cinder create --display-name dbs_vol01 --availability-zone az1 10

wait_for_cinder volume dbs_vol01
cinder list
