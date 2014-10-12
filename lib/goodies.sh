function get_uuid () {
    cat - | grep " id " | awk '{print $4}'
}

function get_fixed_ip () {
    cat - | grep ${1:?} |grep -v from |grep -v sg | awk '{print $5}' | sed -e 's/,//'
}

function get_instane_ip () {
    local SERVER_NAME=${1:?}
    local LOCAL_NET_NAME=${2:?}

    nova show $SERVER_NAME | get_fixed_ip $LOCAL_NET_NAME
}

function wait_instance () {
   local SERVER_NAME=${1:?}
   local NETWORK_NAME=${2:?}
   local RETVAL=1

   echo "### check $SERVER_NAME ACTIVE"
   while [ $RETVAL -eq 1 ]
   do
       nova list | grep $SERVER_NAME | grep ACTIVE | grep $NETWORK_NAME > /dev/null
       RETVAL=$?
       if [ $RETVAL -eq 1 ]; then
           echo "### (30sec)wait $SERVER_NAME to become ACTIVE"
           sleep 30
       fi
   done
}

function wait_ping_resp () {
    local TARGET=${1:?}
    local RETVAL=1

    echo "### check ping response from $TARGET"
    while [ $RETVAL -eq 1 ]
    do
        ping -c 1 $TARGET > /dev/null
        RETVAL=$?
        if [ $RETVAL -eq 1 ]; then
            echo "### (30sec)wait ping response from $TARGET"
            sleep 30
        fi
    done
}

function wait_yum_pip () {
    local TARGET=${1:?}
    local YUMRETVAL=0
    local PIPRETVAL=0

    echo "### check yum and pip from $TARGET"
    while [ $YUMRETVAL -eq 0 -o $PIPRETVAL -eq 0 ]
    do
        YUMRETVAL=`ssh -o 'StrictHostKeyChecking no' -i key-for-internal.pem root@${TARGET:?} 'ps -ef |grep -v grep |grep yum > /dev/null 2>&1;echo -n $?'`
        PIPRETVAL=`ssh -o 'StrictHostKeyChecking no' -i key-for-internal.pem root@${TARGET:?} 'ps -ef |grep -v grep |grep pip > /dev/null 2>&1;echo -n $?'`

        if [ $YUMRETVAL -eq 0 -o $PIPRETVAL -eq 0 ]; then
            echo "### (10sec)wait to end yum or pip from $TARGET"
            sleep 10
        fi
    done
}
