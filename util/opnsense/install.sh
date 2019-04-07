#!/usr/bin/env sh

DIR=$(cd `dirname $0` && pwd)

# Make service links
ln -Fs /var/etc/acme-client/home/ /root/.acme.sh

# Install action
ln -Fs ${DIR}/actions_deploy_freenas.conf /usr/local/opnsense/service/conf/actions.d/actions_deploy_freenas.conf

# Reload config daemon
service configd restart
