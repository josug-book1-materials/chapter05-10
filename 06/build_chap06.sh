#!/bin/bash

cd $(dirname $0)

OPENRC=$HOME/openrc
ENVFILE=../lib/env.sh
GOODIESFILE=../lib/goodies.sh
WORK_DIR=$HOME/work_chapter

source $OPENRC
source $ENVFILE
source $GOODIESFILE

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
cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
cd /root
git clone -q https://github.com/josug-book1-materials/sample-app.git
cd sample-app
git checkout -b v1.0 remotes/origin/v1.0
sh /root/sample-app/server-setup/install_web.sh
" >> $USERDATA_NAME

USERDATA_NAME=userdata_app.txt
echo "### create userdata file for $USERDATA_NAME"
echo "#!/bin/bash" > $USERDATA_NAME
echo "
cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
cd /root
git clone -q https://github.com/josug-book1-materials/sample-app.git
cd sample-app
git checkout -b v1.0 remotes/origin/v1.0
sh /root/sample-app/server-setup/install_rest.sh
" >> $USERDATA_NAME

USERDATA_NAME=userdata_dbs.txt
echo "### create userdata file for $USERDATA_NAME"
echo "#!/bin/bash" > $USERDATA_NAME
echo "
cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
cd /root
git clone -q https://github.com/josug-book1-materials/sample-app.git
cd sample-app
git checkout -b v1.0 remotes/origin/v1.0
sh /root/sample-app/server-setup/install_db.sh
" >> $USERDATA_NAME


function get_uuid () { cat - | grep " id " | awk '{print $4}'; }
export MY_DMZ_NET=`neutron net-show dmz-net | get_uuid`
export MY_APP_NET=`neutron net-show app-net | get_uuid`
export MY_DBS_NET=`neutron net-show dbs-net | get_uuid`

echo "### boot servers"
nova boot --flavor standard.xsmall --image "centos-base" \
--key-name key-for-internal --user-data userdata_web.txt \
--security-groups sg-all-from-console,sg-web-from-internet,sg-all-from-app-net \
--availability-zone az1 --nic net-id=${MY_DMZ_NET} --nic net-id=${MY_APP_NET} \
web01

nova boot --flavor standard.xsmall --image "centos-base" \
--key-name key-for-internal --user-data userdata_app.txt \
--security-groups sg-all-from-console,sg-all-from-app-net,sg-all-from-dbs-net \
--availability-zone az1 --nic net-id=${MY_DMZ_NET} --nic net-id=${MY_APP_NET} --nic net-id=${MY_DBS_NET} \
app01

nova boot --flavor standard.xsmall --image "centos-base" \
--key-name key-for-internal --user-data userdata_dbs.txt \
--security-groups sg-all-from-console,sg-all-from-dbs-net \
--availability-zone az1 --nic net-id=${MY_DMZ_NET} --nic net-id=${MY_DBS_NET} \
dbs01


wait_instance web01 dmz-net
wait_instance app01 dmz-net
wait_instance dbs01 dmz-net

WEB01_IP=`get_instane_ip web01 dmz-net`
APP01_IP=`get_instane_ip app01 dmz-net`
DBS01_IP=`get_instane_ip dbs01 dmz-net`

wait_ping_resp $WEB01_IP
wait_ping_resp $APP01_IP
wait_ping_resp $DBS01_IP

echo "### (30sec)wait step-server to start sshd"
sleep 30

wait_yum_pip $WEB01_IP
wait_yum_pip $APP01_IP
wait_yum_pip $DBS01_IP

MYSQL_IP=`get_instane_ip dbs01 dbs-net`
REST_IP=`get_instane_ip app01 app-net`

cat << EOF > endpoint.conf.app01
[db-server]
db_host = $MYSQL_IP
db_endpoint = mysql://user:password@%(db_host)s/sample_bbs?charset=utf8
EOF

cat << EOF > endpoint.conf.web01
[rest-server]
rest_host = $REST_IP
rest_endpoint = http://%(rest_host)s:5555/bbs
EOF


scp -o 'StrictHostKeyChecking no' -i key-for-internal.pem endpoint.conf.app01 root@${APP01_IP:?}:/root/sample-app/endpoint.conf
ssh -o 'StrictHostKeyChecking no' -i key-for-internal.pem root@${APP01_IP:?} "ps -ef > /root/ps.txt"
ssh -o 'StrictHostKeyChecking no' -i key-for-internal.pem root@${APP01_IP:?} "pip freeze > /root/pip.txt"
ssh -o 'StrictHostKeyChecking no' -i key-for-internal.pem root@${APP01_IP:?} "sh /root/sample-app/server-setup/rest.init.sh start"

sleep 5

scp -o 'StrictHostKeyChecking no' -i key-for-internal.pem endpoint.conf.web01 root@${WEB01_IP:?}:/root/sample-app/endpoint.conf
ssh -o 'StrictHostKeyChecking no' -i key-for-internal.pem root@${WEB01_IP:?} "ps -ef > /root/ps.txt"
ssh -o 'StrictHostKeyChecking no' -i key-for-internal.pem root@${WEB01_IP:?} "pip freeze > /root/pip.txt"
ssh -o 'StrictHostKeyChecking no' -i key-for-internal.pem root@${WEB01_IP:?} "sh /root/sample-app/server-setup/web.init.sh start"


echo "### attach floating ip"
WEB_SERVER_FIP=`nova floating-ip-create $EXT_NET_NAME | grep $EXT_NET_NAME | awk '{print $2}'`
nova floating-ip-associate web01 ${WEB_SERVER_FIP:?}

sleep 5

curl http://$WEB_SERVER_FIP

echo "### end script"
