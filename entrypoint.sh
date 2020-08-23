#!/bin/bash

# Add local user
# Either use the LOCAL_USER_ID if passed in at runtime or fallback

IFS=':' read -r -a array <<< "$LOCAL_USER_ID"
uid=$([[ ! -z ${array[0]} ]] && echo ${array[0]} || echo 1000);
gid=$([[ ! -z ${array[1]} ]] && echo ${array[1]} || echo 1000);

echo "Starting with user : UID ${uid} - GID ${gid}"

#if [ ! $(getent group $gid) ]; then
#    echo "GID ${gid} does not exists"
#    groupadd -g $gid -o group
#    echo "GID ${gid} created"
#fi

#useradd --shell /bin/bash -u $uid -o -c "" -m user
#echo "UID ${uid} created"

export HOME=/work

if [ $USER_HOME_COPYSOURCE ]; then
  echo "copying files from dynamic additional files for homedir to /home/devops"
  cp -H $USER_HOME_COPYSOURCE/* /home/devops/ -R
  chown $uid:$gid /home/devops -R
  chmod -R 600 /home/devops/
  chmod -R 700 /home/devops/*.sh
fi

exec /usr/local/bin/gosu $uid:$gid "$@"
