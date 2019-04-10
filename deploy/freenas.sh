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

  _fullchain=$(tr '\n\r' '@#' <"$_cfullchain" | sed 's/@/\\n/g;s/#/\\r/g')
  _key=$(tr '\n\r' '@#' <"$_ckey" | sed 's/@/\\n/g;s/#/\\r/g')

  _debug _fullchain "$_fullchain"
  _debug _key "$_key"

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

  _api_base="${Le_Deploy_FreeNAS_host}/api/v1.0"
#  _cert=$(date +letsencrypt-%Y-%m-%d-%H%M%S)
  _cert=$(date +letsencrypt-%Y-%m-%d)
  _realm=$(printf "%s:%s" "root" "$Le_Deploy_FreeNAS_password" | _base64)

  _debug _api_base "$_api_base"
  _debug _cert "$_cert"
  _debug _realm "$_realm"

  _info "Update or create SSL certificate"
  export _H1="Authorization: Basic $_realm"
  export _H2="Content-Type: application/json"
  _request="{\"cert_name\":\"$_cert\",\"cert_certificate\":\"$_fullchain\",\"cert_privatekey\":\"$_key\"}"
  _debug _request "$_request"
  _response="$(_post "$_request" "$_api_base/system/certificate/import/")"
  _debug _response "$_response"

  if echo "$_response" | grep -q "certificate with this name already exists"; then
    _err "SSL certificate with name '$_cert' are already exists. Stop deploying"
    return 0
  elif [ "$_response" != "Certificate imported." ]; then
    _err "Error SSL certificate import"
    return 1
  fi

  _info "Download certificate list and parse it to find the ID that matches our cert name"
  _response=$(_get "$_api_base/system/certificate/?limit=0")
  _debug _response "$_response"
  _regex="^.*\"cert_name\": *\"$_cert\".*$"
  _debug _regex "$_regex"
  _resource=$(echo "$_response" | sed 's/},{/},\n{/g' | _egrep_o "$_regex")
  _debug _resource "$_resource"
  _regex="^.*\"cert_name\": \"$_cert\".*$"
  _debug _regex "$_regex"
  _resource=$(echo "$_response" | sed 's/},{/},\n{/g' | _egrep_o "$_regex")
  _debug _resource "$_resource"
  _regex=".*\"id\": *\([0-9]*\).*$"
  _debug _regex "$_regex"
  _cert_id=$(echo "$_resource" | sed -n "s/$_regex/\1/p")
  _debug _resourceId "$_cert_id"

  _info "Set our cert as active"
  _request="{\"stg_guicertificate\":\"$_cert_id\"}"
  _response=$(_post "$_request" "$_api_base/system/settings/" '' "PUT")
  _debug _response "$_response"

  _info "Reload nginx with new cert"
  _response="$(_post "" "$_api_base/system/settings/restart-httpd-all/")"
  _debug _response "$_response"

  # Make time for httpd for reloading
  sleep 3

  _info "Set our cert as active for FTP plugin"
  _request="{\"ftp_ssltls_certfile\":\"$_cert\"}"
  _response=$(_post "$_request" "$_api_base/services/ftp/" '' "PUT")
  _debug _response "$_response"

  _info "Certificate successfully deployed"
  return 0
}
