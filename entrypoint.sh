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

if [[ -z "${USER_HOME_COPYSOURCE}" ]]; then
  echo "USER_HOME_COPYSOURCE is undefined, set this variable to define a different in-container folder source to copy e.g. gpg data from to the user homedir"
else
  echo "copying files from dynamic additional files for homedir to /home/devops"
  cp -H $USER_HOME_COPYSOURCE/* /root/ -R
  chmod -R 744 /root/*.sh
fi

chown $uid:$gid /root -R
chown $uid:$gid /work -R

exec "$@"
#exec /usr/local/bin/gosu $uid:$gid "$@"
