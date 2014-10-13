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


USERDATA_NAME=userdata_lbs.txt
echo "### create userdata file for $USERDATA_NAME"
echo "#!/bin/bash" > $USERDATA_NAME
echo "
cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
cat << EOF > /etc/yum.repos.d/nginx.repo
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/\\\$releasever/\\\$basearch/
gpgcheck=0
enabled=1
EOF
yum install -q -y nginx
chkconfig nginx on
/etc/init.d/nginx start
" >> $USERDATA_NAME

export MY_DMZ_NET=`neutron net-show dmz-net | get_uuid`
export MY_APP_NET=`neutron net-show app-net | get_uuid`
export MY_DBS_NET=`neutron net-show dbs-net | get_uuid`

echo "### boot lbs01 servers"
nova boot --flavor standard.xsmall --image "centos-base" \
--key-name key-for-internal --user-data userdata_lbs.txt \
--security-groups sg-all-from-console,sg-web-from-internet \
--availability-zone az1 --nic net-id=${MY_DMZ_NET} \
lbs01


echo "### boot web02 servers"
nova boot --flavor standard.xsmall --image "centos-base" \
--key-name key-for-internal --user-data userdata_web.txt \
--security-groups sg-all-from-console,sg-web-from-internet,sg-all-from-app-net \
--availability-zone az1 --nic net-id=${MY_DMZ_NET} --nic net-id=${MY_APP_NET} \
web02

wait_instance web02 dmz-net

WEB02_IP=`get_instane_ip web02 dmz-net`

wait_ping_resp $WEB02_IP

echo "### (30sec)wait step-server to start sshd"
sleep 30

wait_yum_pip $WEB02_IP

REST_IP=`get_instane_ip app01 app-net`

cat << EOF > endpoint.conf.web02
[rest-server]
rest_host = $REST_IP
rest_endpoint = http://%(rest_host)s:5555/bbs
EOF


scp -o 'StrictHostKeyChecking no' -i key-for-internal.pem endpoint.conf.web02 root@${WEB02_IP:?}:/root/sample-app/endpoint.conf
ssh -o 'StrictHostKeyChecking no' -i key-for-internal.pem root@${WEB02_IP:?} "ps -ef > /root/ps.txt"
ssh -o 'StrictHostKeyChecking no' -i key-for-internal.pem root@${WEB02_IP:?} "pip freeze > /root/pip.txt"
ssh -o 'StrictHostKeyChecking no' -i key-for-internal.pem root@${WEB02_IP:?} "shutdown -h now"

#ssh -o 'StrictHostKeyChecking no' -i key-for-internal.pem root@${WEB02_IP:?} "sh /root/sample-app/server-setup/web.init.sh start"


#echo "### attach floating ip"
#WEB_SERVER_FIP=`nova floating-ip-create $EXT_NET_NAME | grep $EXT_NET_NAME | awk '{print $2}'`
#nova floating-ip-associate web01 ${WEB_SERVER_FIP:?}

#sleep 5

#curl http://$WEB_SERVER_FIP

#cat << EOF > lbs.conf
#upstream web-server {
#  server 192.168.0.1:80;
#}
#
#server {
#  listen       80 default_server;
#  server_name  _;
#
#  location / {
#    proxy_pass http://web-server/;
#  }
#}
#EOF
echo "### end script"
