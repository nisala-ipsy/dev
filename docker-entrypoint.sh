#!/bin/sh
set -e
mkdir -p /var/run/sshd
ssh-keygen -A >/dev/null
/usr/sbin/sshd
exec runuser -u dev -- "$@"
