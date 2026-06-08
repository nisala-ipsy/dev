#!/bin/sh
set -e
dev_home="$(getent passwd dev | cut -d: -f6)"
mkdir -p /var/run/sshd
ssh-keygen -A >/dev/null
/usr/sbin/sshd
exec runuser -u dev -- env HOME="$dev_home" USER=dev LOGNAME=dev "$@"
