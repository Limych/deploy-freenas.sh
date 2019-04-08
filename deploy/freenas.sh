#!/usr/bin/env sh

# Script to deploy certificate to a FreeNAS server

# The following variables exported from environment will be used.
# If not set then values previously saved in domain.conf file are used.

# Required variables:
# export FREENAS_PASSWORD="xxxxxxx"
#
# Optional variables (default values described):
# export FREENAS_HOST="http://localhost:80"
# export FREENAS_VERIFY=false

#domain keyfile certfile cafile fullchain
freenas_deploy() {
  _cdomain="$1"
  _ckey="$2"
  _ccert="$3"
  _cca="$4"
  _cfullchain="$5"

  _debug _cdomain "$_cdomain"
  _debug _ckey "$_ckey"
  _debug _ccert "$_ccert"
  _debug _cca "$_cca"
  _debug _cfullchain "$_cfullchain"

  if [ -z "$FREENAS_PASSWORD" ]; then
    if [ -z "$Le_Deploy_FreeNAS_password" ]; then
      _err "FREENAS_PASSWORD not defined."
      return 1
    fi
  else
    Le_Deploy_FreeNAS_password="$FREENAS_PASSWORD"
    _savedomainconf Le_Deploy_FreeNAS_password "$Le_Deploy_FreeNAS_password"
  fi

  if [ -z "$FREENAS_HOST" ]; then
    if [ -z "$Le_Deploy_FreeNAS_host" ]; then
      Le_Deploy_FreeNAS_host="http://localhost:80"
      _savedomainconf Le_Deploy_freenas_host "$Le_Deploy_FreeNAS_host"
    fi
  else
    Le_Deploy_FreeNAS_host="$FREENAS_HOST"
    _savedomainconf Le_Deploy_freenas_host "$Le_Deploy_FreeNAS_host"
  fi

  if [ -z "$FREENAS_VERIFY" ]; then
    if [ -z "$Le_Deploy_FreeNAS_verify" ]; then
      Le_Deploy_FreeNAS_verify=false
      _savedomainconf Le_Deploy_FreeNAS_verify "$Le_Deploy_FreeNAS_verify"
    fi
  else
    Le_Deploy_FreeNAS_verify="$FREENAS_VERIFY"
    _savedomainconf Le_Deploy_FreeNAS_verify "$Le_Deploy_FreeNAS_verify"
  fi

  api_base="${Le_Deploy_FreeNAS_host}/api/v1.0"
  cert=$(date +letsencrypt-%Y-%m-%d-%H%M%S)
  credentials=$(printf "%s:%s" "root" "$Le_Deploy_FreeNAS_password" | _base64)

  _err "Not implemented yet"
  return 1
}