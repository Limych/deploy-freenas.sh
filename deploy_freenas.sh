#!/usr/bin/env sh



_locate() {
  fname=$1
  shift
  for dir in $*; do
    dir=$(cd ${dir} 2>/dev/null && pwd)
    if [ -r "${dir}/${fname}" ]; then echo "${dir}/${fname}"; exit; fi
  done
}



WDIR=$(cd `dirname $0` && pwd)

FETCH=$(which fetch 2>/dev/null)
CURL=$(which curl 2>/dev/null)
WGET=$(which wget 2>/dev/null)

IS_OPNSENSE=$([ -d "/usr/local/opnsense/" ] && echo 1)

# Locate acme.sh and load it as a library
ACME=$(_locate acme.sh /root/.acme.sh /usr/local/sbin "$WDIR")

if [ -z "$ACME" ] || [ ! -z "$(find "$WDIR/acme.sh" -mtime +30 2>/dev/null)" ]; then
  if [ ! -z "$FETCH" ]; then
    "$FETCH" https://raw.githubusercontent.com/Neilpang/acme.sh/master/acme.sh
  elif [ ! -z "$CURL" ]; then
    "$CURL" -O https://raw.githubusercontent.com/Neilpang/acme.sh/master/acme.sh
  elif [ ! -z "$WGET" ]; then
    "$WGET" https://raw.githubusercontent.com/Neilpang/acme.sh/master/acme.sh
  fi
  ACME=$(_locate acme.sh "$WDIR")
fi
if [ -z "$ACME" ]; then echo "ERROR: Can't locate acme.sh"; exit 1; fi

if [ "$IS_OPNSENSE" == "1" ]; then
  LE_WORKING_DIR="/var/etc/acme-client/home"
  _SCRIPT_HOME="$WDIR"
else
  LE_WORKING_DIR=`dirname $ACME`
fi

. "$ACME" >/dev/null



_parse_ini() {
	inFile="$1"
	prefix="${2:-ini}"

	if [ ! -f "$inFile" ]; then _err "File $inFile not found!"; exit 1; fi

	local IFS="="
	echo "[]" | cat "$inFile" - | sed 's/\\t/ /g;s/^ +//;s/ +$//;/^#/d;/^$/d' | while read name value; do
    name=$(echo ${name} | sed 's/ *$//')
		[ -z "$name" ] && continue

		local IFS=" "
		if [ $(echo ${name} | cut -c 1-1) == "[" ]; then
      section=$(echo ${name} | sed 's/\[//;s/\]//')
		else
      value=$(echo ${value} | sed 's/[#%][ "]//;s/"/\\"/')
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
CERT_KEY_PATH=${ini__deploy__privkey_path:-"/root/.acme.sh/${DOMAIN_NAME}/${DOMAIN_NAME}.key"}
CERT_FULLCHAIN_PATH=${ini__deploy__fullchain_path:-"/root/.acme.sh/${DOMAIN_NAME}/fullchain.cer"}
export FREENAS_PASSWORD=${ini__deploy__password}
export FREENAS_HOST="${ini__deploy__protocol:-"http://"}${ini__deploy__connect_host:-"localhost"}:${ini__deploy__port:-"80"}"
export FREENAS_VERIFY=${ini__deploy__verify:-"true"}

_debug DOMAIN_NAME "$DOMAIN_NAME"
_debug CERT_KEY_PATH "$CERT_KEY_PATH"
_debug CERT_FULLCHAIN_PATH "$CERT_FULLCHAIN_PATH"
_debug FREENAS_PASSWORD "$FREENAS_PASSWORD"
_debug FREENAS_HOST "$FREENAS_HOST"
_debug FREENAS_VERIFY "$FREENAS_VERIFY"

. "$WDIR/deploy/freenas.sh"

freenas_deploy "$DOMAIN_NAME" "$CERT_KEY_PATH" "" "" "$CERT_FULLCHAIN_PATH"
