#!/bin/bash

cd $(dirname $0)

OPENRC=$HOME/openrc
ENVFILE=../env.sh
WORK_DIR=$HOME/work_chap06


source $OPENRC
source $ENVFILE

mkdir -p $WORK_DIR
cd $WORK_DIR


echo "### create secgroups"
neutron security-group-create sg-web-from-internet
neutron security-group-create sg-all-from-app-net
neutron security-group-create sg-all-from-dbs-net
neutron security-group-create sg-all-from-console

neutron security-group-rule-create --ethertype IPv4 --protocol tcp \
--port-range-min 80 --port-range-max 80 \
--remote-ip-prefix 0.0.0.0/0 sg-web-from-internet
neutron security-group-rule-create --ethertype IPv4 --protocol tcp \
--port-range-min 443 --port-range-max 443 \
--remote-ip-prefix 0.0.0.0/0 sg-web-from-internet

neutron security-group-rule-create --ethertype IPv4 --protocol tcp \
--port-range-min 1 --port-range-max 65535 \
--remote-ip-prefix 172.16.10.0/24 sg-all-from-app-net
neutron security-group-rule-create --ethertype IPv4 --protocol icmp \
--remote-ip-prefix 172.16.10.0/24 sg-all-from-app-net

neutron security-group-rule-create --ethertype IPv4 --protocol tcp \
--port-range-min 1 --port-range-max 65535 \
--remote-ip-prefix 172.16.20.0/24 sg-all-from-dbs-net
neutron security-group-rule-create --ethertype IPv4 --protocol icmp \
--remote-ip-prefix 172.16.20.0/24 sg-all-from-dbs-net

neutron security-group-rule-create --ethertype IPv4 --protocol tcp \
--port-range-min 1 --port-range-max 65535 \
--remote-ip-prefix 10.0.0.0/24 sg-all-from-console
neutron security-group-rule-create --ethertype IPv4 --protocol icmp \
--remote-ip-prefix 10.0.0.0/24 sg-all-from-console



echo "### create keypair"
nova keypair-add key-for-internal | tee key-for-internal.pem
chmod 600 key-for-internal.pem



USERDATA_NAME=userdata_web.txt
echo "### create userdata file for $USERDATA_NAME"
echo "#!/bin/bash" > $USERDATA_NAME
echo "

" >> $USERDATA_NAME




function get_uuid () { cat - | grep " id " | awk '{print $4}'; }
export MY_DMZ_NET=`neutron net-show dmz-net | get_uuid`
export MY_APP_NET=`neutron net-show app-net | get_uuid`
export MY_DBS_NET=`neutron net-show dbs-net | get_uuid`







echo "### boot step-server"

retval=1
while [ $retval -eq 1 ]
do
    echo "### (30sec)wait step-server to become ACTIVE"
    sleep 30
    nova list | grep step-server | grep ACTIVE | grep work-net
    retval=$?
done
nova list --field name,status,networks


echo "### attach floating ip"
STEP_SERVER_IP=`nova floating-ip-create $EXT_NET_NAME | grep $EXT_NET_NAME | awk '{print $2}'`
nova floating-ip-associate step-server ${STEP_SERVER_IP:?}


echo "### (30sec)wait step-server to start sshd"
sleep 30


echo "### access test to step server"
ssh -o 'StrictHostKeyChecking no' -i key-for-step-server.pem root@${STEP_SERVER_IP:?} hostname


echo "### create virtual networks for SNSapp"
neutron net-create dmz-net
neutron net-create app-net
neutron net-create dbs-net
neutron subnet-create --ip-version 4 --gateway 192.168.0.254 \
--name dmz-subnet dmz-net 192.168.0.0/24
neutron subnet-create --ip-version 4 --no-gateway \
--name app-subnet app-net 172.16.10.0/24
neutron subnet-create --ip-version 4 --no-gateway \
--name dbs-subnet dbs-net 172.16.20.0/24

neutron router-interface-add Ext-Router dmz-subnet

echo "### end script"

