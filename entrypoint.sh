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

export HOME=/root

if [[ -z "${USER_HOME_COPYSOURCE}" ]]; then
  echo "USER_HOME_COPYSOURCE is undefined, set this variable to define a different in-container folder source to copy e.g. gpg data from to the user homedir"
else
  echo "copying files from dynamic additional files for homedir to /root"
  cp -H $USER_HOME_COPYSOURCE /root/ -R
  chmod -R 744 /root/**/*.sh
  chmod -R 744 /root/*.sh
fi

if [ ! -d "/root/.gpgimport" ]; then
  mkdir /root/.gpgimport
  echo "empty .gpgimport directory created under /root/.gpgimport"
fi

echo "import your mounted gpg keys"
gpg --import /root/.gpgimport/*
echo "import of gpg keys done"

echo "setting ownage of /root dir to user root"
chown root:root /root -R
#chown root:root /work -R

exec "$@"
#exec /usr/local/bin/gosu $uid:$gid "$@"
