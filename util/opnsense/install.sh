#!/usr/bin/env sh

WDIR=$(cd `dirname $0` && pwd)

# Install cron action
ln -Fs ${WDIR}/actions_deploy_freenas.conf /usr/local/opnsense/service/conf/actions.d/actions_deploy_freenas.conf

# Reload config daemon
service configd restart
