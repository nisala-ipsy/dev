#!/bin/sh
set -e
sudo ssh-keygen -A >/dev/null
sudo /usr/sbin/sshd
exec "$@"
