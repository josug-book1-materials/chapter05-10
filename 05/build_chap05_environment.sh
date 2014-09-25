#!/bin/bash

WORK_DIR=$HOME/chap05
OPENRC=$HOME/openrc
ENVFILE=$HOME/josug-book1-materials/chapter05-10/env.sh

source $OPENRC
source $ENVFILE

mkdir -p $WORK_DIR
cd $WORK_DIR

echo "### create Ext-Router"
neutron router-create Ext-Router
neutron router-gateway-set Ext-Router $EXT_NET_NAME

echo "### create work-net"
neutron net-create work-net
neutron subnet-create --ip-version 4 --gateway 10.0.0.254 \
--name work-subnet \
--dns-nameserver $DNS_SERVER_1st \
--dns-nameserver $DNS_SERVER_2nd \
work-net 10.0.0.0/24
neutron router-interface-add Ext-Router work-subnet

echo "### create keypair"
nova keypair-add key-for-step-server | tee key-for-step-server.pem
chmod 600 key-for-step-server.pem

echo "### create secgroup"
neutron security-group-create --description "secgroup for step server" sg-for-step-server
neutron security-group-rule-create --ethertype IPv4 \
--protocol tcp --port-range-min 22 --port-range-max 22 \
--remote-ip-prefix 0.0.0.0/0 sg-for-step-server

echo "### create userdata file"
echo "#!/bin/bash" > userdata_step-server.txt
echo "
cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
yum install -q -y http://rdo.fedorapeople.org/rdo-release.rpm
yum install -q -y python-novaclient \
 python-neutronclient \
 python-glanceclient \
 python-cinderclient \
 python-swiftclient \
 python-keystoneclient
cat << EOF > /root/openrc
export OS_AUTH_URL=${OS_AUTH_URL}
export OS_REGION_NAME=${OS_REGION_NAME}
export OS_TENANT_NAME=${OS_TENANT_NAME}
export OS_USERNAME=${OS_USERNAME}
export OS_PASSWORD=${OS_PASSWORD}
EOF
" >> userdata_step-server.txt

echo "### boot step-server"
function get_uuid () { cat - | grep " id " | awk '{print $4}'; }
export MY_WORK_NET=`neutron net-show work-net | get_uuid`
nova boot --flavor standard.xsmall \
--image "${IMAGE_NAME}" \
--key-name key-for-step-server \
--security-groups sg-for-step-server  \
--user-data userdata_step-server.txt \
--availability-zone ${AZ_NAME} \
--nic net-id=${MY_WORK_NET} step-server


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

