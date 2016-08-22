#!/bin/bash 
function debug_out {  
  if [ "$DEBUG" == "1" ]
    then
      echo $1 
  fi
}  

function run_test {
KITCHEN_FLAGS=""
if [ "$DEBUG" == "1" ]
  then
    echo "Keypair : $KEYPAIR"
    cat $KEYPAIR_FILENAME
    kitchen diagnose
    KITCHEN_FLAGS="-l debug" 
fi
kitchen destroy
kitchen create $KITCHEN_FLAGS> >(tee -a /tmp/stdout-${BUILD}.log) 2> >(tee -a /tmp/stderr-${BUILD}.log >&2)  || {
  ERR=$?
  exit $ERR
}
kitchen converge $KITCHEN_FLAGS> >(tee -a /tmp/stdout-${BUILD}.log) 2> >(tee -a /tmp/stderr-${BUILD}.log >&2)  || {
  ERR=$?
  exit $ERR
}
kitchen setup $KITCHEN_FLAGS> >(tee -a /tmp/stdout-${BUILD}.log) 2> >(tee -a /tmp/stderr-${BUILD}.log >&2) || {
  ERR=$?
  exit $ERR
}

kitchen verify $KITCHEN_FLAGS> >(tee -a /tmp/stdout-${BUILD}.log) 2> >(tee -a /tmp/stderr-${BUILD}.log >&2) || {
  ERR=$?
  echo "cat << EOF > /tmp/tmp_key.$$"
  cat $KEYPAIR_FILENAME
  echo "EOF"
  echo "chmod 0700  /tmp/tmp_key.$$"
  IP=`grep "Attaching floating IP" /tmp/stdout-${BUILD}.log | tail -1 | sed -e 's/^.*<//' -e 's/>$//' -e 's/ *//g'`
  echo "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentityFile=/tmp/tmp_key.$$ -o IdentitiesOnly=yes ${IMAGE_USERNAME}@${IP} -i /tmp/tmp_key.$$"
  echo "rm /tmp/tmp_key.$$"
  let TOTAL_TIME=${SLEEPTIME:=1200}
  let EACH_LOOP=TOTAL_TIME/100
  for ((n=1;n<101;n++))
  do
    echo "$n of 100...."
    sleep $EACH_LOOP
  done
  rm -f /tmp/stdout-${BUILD}.log  /tmp/stderr-${BUILD}.log
  kitchen destroy
  openstack keypair delete $KEYPAIR
  exit $ERR
 }
IP=`grep "Attaching floating IP" /tmp/stdout-${BUILD}.log | tail -1 | sed -e 's/^.*<//' -e 's/>$//' -e 's/ *//'`
}

export BUILD="${CI_BUILD_REF}_$(date +%Y%m%d%H%M%S)_${MODE}"
export KEYPAIR="${CI_BUILD_ID}${MODE}"
export KEYPAIR_FILENAME="${KEYPAIR}"
openstack keypair create $KEYPAIR > $KEYPAIR_FILENAME
chmod 700 $KEYPAIR_FILENAME
run_test
rm -f /tmp/stdout-${BUILD}.log  /tmp/stderr-${BUILD}.log 
kitchen destroy
openstack keypair delete $KEYPAIR
