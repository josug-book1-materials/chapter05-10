function get_uuid () {
    cat - | grep " id " | awk '{print $4}'
}

function get_fixed_ip () {
    cat - | grep ${1:?} | awk '{print $5}' | sed -e 's/,//'
}

function wait_instance () {
   local SERVER_NAME=${1:?}
   local NETWORK_NAME=${2:?}
   local RETVAL=1
   while [ $RETVAL -eq 1 ]
   do
       echo "### (30sec)wait $SERVER_NAME to become ACTIVE"
       sleep 30
       nova list | grep $SERVER_NAME | grep ACTIVE | grep $NETWORK_NAME > /dev/null
       RETVAL=$?
   done
}

function wait_ping_resp () {
    local TARGET=${1:?}
    local RETVAL=1
    while [ $RETVAL -eq 1 ]
    do
        echo "### (30sec)wait ping response from $TARGET"
        sleep 30
        ping -c 1 $TARGET > /dev/null
        RETVAL=$?
    done
}

function get_instane_ip () {
    local SERVER_NAME=${1:?}
    local LOCAL_NET_NAME=${2:?}

    nova show $SERVER_NAME | get_fixed_ip $LOCAL_NET_NAME
}
