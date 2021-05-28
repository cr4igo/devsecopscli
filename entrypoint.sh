#!/bin/bash

if [ -d "/root/.gpgimport" ]; then
  echo "found .gpgimport directory under /root/.gpgimport"
  echo "import your mounted gpg keys"
  # for each file in /root/.gpgimport with ending .pgp
  for filename in /root/.gpgimport/*.asc; do
    gpg --import ${filename}
  done
  echo "import of gpg keys done"
fi

exec "$@"
