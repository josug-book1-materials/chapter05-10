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



echo "### delete servers"
nova delete web01
nova delete app01
nova delete dbs01
nova keypair-delete key-for-internal

echo "### delete secgroups"
neutron security-group-delete sg-web-from-internet
neutron security-group-delete sg-all-from-app-net
neutron security-group-delete sg-all-from-dbs-net
neutron security-group-delete sg-all-from-console

echo "### check status"
nova list
nova keypair-list
nova secgroup-list
neutron net-list
nova floating-ip-list
echo "### end script"

