#!/usr/bin/env sh

DEBUG=3



_locate() {
  fname=$1
  shift
  for dir in $*; do
    dir=$(cd ${dir} 2>/dev/null && pwd)
    if [ -x "${dir}/${fname}" ]; then echo "${dir}/${fname}"; exit; fi
  done
}



WDIR=$(cd `dirname $0` && pwd)

# Locate acme.sh and load it as a library
ACME=$(_locate acme.sh /root/.acme.sh /usr/local/sbin ${WDIR})
LE_WORKING_DIR=`dirname $ACME`

if [ -z "$ACME" ]; then echo "ERROR: Can't locate acme.sh!"; exit 1; fi

. $ACME >/dev/null



_parse_ini() {
	inFile="$1"
	prefix="${2:-ini}"

	if [ ! -f "$inFile" ]; then _err "File $inFile not found!"; exit 1; fi

	local IFS="="
	echo "[]" | cat "$inFile" - | sed 's/\t/ /g;s/^ +//;s/ +$//;/^#/d;/^$/d' | while read name value; do
    name=${name/ /}
		[ -z "$name" ] && continue

		local IFS=" "
		if [ "${name:0:1}" == "[" ]; then
			section=${name/'['/}
			section=${section/']'/}
		else
      value=${value/# /}
      value=${value/% /}
      value=${value/#\"/}
      value=${value/%\"/}

      value=${value//\"/\\\"}
      echo "${prefix}__${section}__${name}=\"${value}\""
		fi
		local IFS="="
	done
}



# Parse configuration file
CONFIG=$(_locate deploy_config ${WDIR}/../.. ${WDIR})

if [ -z "$CONFIG" ]; then _err "ERROR: Can't locate deploy_config!"; exit 1; fi

eval $(_parse_ini ${CONFIG})

if [ -z "${ini__deploy__password}" ]; then _err "ERROR: Root password not defined!"; exit 1; fi

DOMAIN_NAME=${ini__deploy__cert_fqdn:-$(hostname)}
PRIVKEY_PATH=${ini__deploy__privkey_path:-"/root/.acme.sh/${DOMAIN_NAME}/${DOMAIN_NAME}.key"}
FULLCHAIN_PATH=${ini__deploy__fullchain_path:-"/root/.acme.sh/${DOMAIN_NAME}/fullchain.cer"}
FREENAS_API_BASE="${ini__deploy__protocol:-"http://"}${ini__deploy__connect_host:-"localhost"}:${ini__deploy__port:-"80"}/api/v1.0"
FREENAS_USER="root"
FREENAS_PASSWORD=${ini__deploy__password}
FREENAS_VERIFY=${ini__deploy__verify:-"true"}
FREENAS_CERT=$(date +letsencrypt-%Y-%m-%d-%H%M%S)
FREENAS_CREDENTIALS=$(printf "%s:%s" "$FREENAS_USER" "$FREENAS_PASSWORD" | _base64)

_debug DOMAIN_NAME ${DOMAIN_NAME}
_debug PRIVKEY_PATH ${PRIVKEY_PATH}
_debug FULLCHAIN_PATH ${FULLCHAIN_PATH}
_debug FREENAS_API_BASE ${FREENAS_API_BASE}
_debug FREENAS_USER ${FREENAS_USER}
_debug FREENAS_PASSWORD ${FREENAS_PASSWORD}
_debug FREENAS_CREDENTIALS ${FREENAS_CREDENTIALS}
_debug FREENAS_VERIFY ${FREENAS_VERIFY}
_debug FREENAS_CERT ${FREENAS_CERT}

# Update or create certificate
#r = requests.post(
#    PROTOCOL + FREENAS_ADDRESS + ':' + PORT + '/api/v1.0/system/certificate/import/',
#    verify=VERIFY,
#    auth=(USER, PASSWORD),
#    headers={'Content-Type': 'application/json'},
#    data=json.dumps({
#    "cert_name": cert,
#    "cert_certificate": full_chain,
#    "cert_privatekey": priv_key,
#    }),
#)
string_fullchain=$(_url_encode <"$FULLCHAIN_PATH")
string_key=$(_url_encode <"$PRIVKEY_PATH")

if [ -z "${string_fullchain}" ] || [ -z "${string_key}" ]; then _err "ERROR: Can't load certificate!"; exit 1; fi

body="{\"cert_name\": \"${FREENAS_CERT}\", \"cert_certificate\": \"${string_fullchain}\", \"cert_privatekey\": \"${string_key}\"}"
export _H1="Authorization: Basic ${FREENAS_CREDENTIALS}"
_response=$(_post "$body" "$FREENAS_API_BASE/system/certificate/import/" 0 POST "application/json" | _dbase64 "multiline")

echo $_response
exit
#
#error_response="error"
#
#if test "${_response#*$error_response}" != "$_response"; then
#  _err "Error in deploying certificate:"
#  _err "$_response"
#  exit 1
#fi
#
#_debug response "$_response"
#_info "Certificate successfully deployed"
