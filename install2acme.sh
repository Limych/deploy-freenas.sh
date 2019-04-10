#!/usr/bin/env sh

WDIR=$(cd `dirname $0` && pwd)
ACME="/root/.acme.sh"

if [ ! -r "$ACME/acme.sh" ]; then echo "ERROR: Can't locate ACME directory"; exit 1; fi

cp -R "$WDIR/deploy/" "$ACME/deploy/"

echo "The SSL certificate deployer for FreeNAS are successfully installed to ACME."
