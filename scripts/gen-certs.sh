#!/bin/sh
die() { echo "$*" 1>&2 ; exit 1; }
if [ $# -eq 0 ]; then die 'Ldap suffix and (or) certdir are missing'; fi
if [ $# -eq 1 ]; then die 'Ldap suffix and (or) certdir are missing'; fi

SUFFIX="$1"
certdir="$2"
mkdir -p "$certdir"
CN="${SUFFIX:-$default_suffix}"
openssl req -x509 -newkey rsa:4096 -keyout "${certdir}"/serverkey.pem -out "${certdir}"/servercert.pem -sha256 -days 3650 -nodes \
	-subj "/C=HL/ST=NewMexico/L=USA/O=BlackMesaResearchFacility/OU=Biohazard/CN=$CN"
