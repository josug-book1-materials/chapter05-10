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


echo "### delete nova instance"
nova delete step-server
sleep 5

echo "### delete keypair & secgroups"
nova keypair-delete key-for-step-server
neutron security-group-delete sg-for-step-server

neutron router-interface-delete Ext-Router work-subnet
neutron router-interface-delete Ext-Router dmz-subnet

echo "### delete networks"
neutron net-delete dmz-net
neutron net-delete app-net
neutron net-delete dbs-net
neutron net-delete work-net

neutron router-delete Ext-Router

echo "### check status"
nova list
nova keypair-list
nova secgroup-list
neutron net-list
nova floating-ip-list
echo "### end script"
