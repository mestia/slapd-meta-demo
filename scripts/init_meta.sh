#!/bin/bash
# initialize meta proxy
# parse docker-compose variables
# initialize default config by enabling meta and ldap backends,
# optionally more backends and overlays
# use template with envsubst to generate the rest of meta config

set -eo pipefail

compose_file_loc='docker-compose.yaml'
openldap_lib_dir='/opt/bitnami/openldap/lib/openldap'
ldif_template='scripts/meta.ldif_template'

# parse docker-compose.yaml, works only for unique options
parse_yaml () {
	local OPT="$1"
	local FILE="$2"
	perl -F"$OPT" -lanE '$F[1]=~s/([\w,\-=\/:]*)/say $1 if $1/ge' "$FILE"
}

parsed_config_pwd=$(parse_yaml 'META_LDAP_CONFIG_ADMIN_PASSWORD:' "$compose_file_loc")
parsed_config_user=$(parse_yaml 'META_LDAP_CONFIG_ADMIN_USERNAME:' "$compose_file_loc")
META_SUFFIX=$(parse_yaml 'META_SUFFIX:' "$compose_file_loc")
META_REMOTE_URI=$(parse_yaml 'META_REMOTE_URI:' "$compose_file_loc")
META_REMOTE_DIR_SUFFIX=$(parse_yaml 'META_REMOTE_DIR_SUFFIX:' "$compose_file_loc")
META_LOCAL_DC=$(parse_yaml 'META_LOCAL_DC:' "$compose_file_loc")
META_LDAPS_PORT=$(parse_yaml 'META_LDAPS_PORT:' "$compose_file_loc")

ldap_conf_pwd="${parsed_config_pwd:-config}"
ldap_conf_user="${parsed_config_user:-admin}"

echo "waiting for LDAPS to come up"
while ! openssl s_client -showcerts --connect localhost:${META_LDAPS_PORT} </dev/null >/dev/null 2>&1
do
    spin='-\|/'
    i=$(( (i+1) %4 ))
    printf "\r${spin:$i:1}"
    sleep .5
done
echo "\n"

for module in back_{meta,ldap} translucent
do
 echo "$module" \
 | perl -snE 'say "dn: cn=module{0},cn=config\nchangetype: modify\nadd: olcModuleLoad\nolcModuleLoad: $module\n-\n"' -- -module="${openldap_lib_dir}"/"$module".la
done \
	| ldapmodify -H ldaps://localhost:${META_LDAPS_PORT} -D "cn=${ldap_conf_user},cn=config" -w${ldap_conf_pwd}

META_LDAP_CONFIG_ROOT_DN="cn=${ldap_conf_user},cn=config" \
META_LOCAL_DC=${META_LOCAL_DC} \
META_SUFFIX=${META_SUFFIX} \
META_REMOTE_URI=${META_REMOTE_URI} \
META_REMOTE_DIR_SUFFIX=${META_REMOTE_DIR_SUFFIX} \
      	envsubst < "$ldif_template" | ldapadd -H ldaps://localhost:1636 -D "cn=${ldap_conf_user},cn=config" -w$ldap_conf_pwd


#ldapmodify -H ldaps://localhost:1636 -D "cn=${ldap_conf_user},cn=config" -w$ldap_conf_pwd <<EOF
#dn: olcDatabase={2}mdb,cn=config
#changetype: modify
#add: olcSubordinate
#olcSubordinate: TRUE
#EOF
