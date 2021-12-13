#!/bin/bash
RUNCOLOR='\033[0;31m'
GREEN='\033[0;32m'
NOCOLOR='\033[0m'
export SLEEPTIME=1

CLUSTERS=$(kind get clusters)
#Ref: https://www.cyberciti.biz/faq/unix-linux-bash-script-check-if-variable-is-empty/
if [ -z "$CLUSTERS" ]
then
      echo "${RUNCOLOR}No Clusters found${NOCOLOR}"
else
      echo "${RUNCOLOR}Cluster found${NOCOLOR}"
      kind get clusters | while read names ; do  echo "${RUNCOLOR}Removing $names${NOCOLOR}" ; kind delete cluster --name=$names ; done
fi

KINDCMD=$(which kind)
if [ -f $KINDCMD ]; then
   echo "${RUNCOLOR}Removing Kind${NOCOLOR}"
   sleep $SLEEPTIME
   rm -rf $KINDCMD
else
  echo "${RUNCOLOR}Kind CMD Not found${NOCOLOR}"
fi


KUBECTLCMD=$(which kubectl)

if [ -f $KUBECTLCMD ]; then
   echo "${RUNCOLOR}Removing kubectl${NOCOLOR}"
   sleep $SLEEPTIME
   rm -rf $KUBECTLCMD
else
  echo "${RUNCOLOR}kubectl CMD Not found${NOCOLOR}"
fi

apt remove -y docker.io