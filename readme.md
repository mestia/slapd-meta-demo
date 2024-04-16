Demo setup of LDAP proxy with meta backend

openldap docker image is based on the bitnami work: https://bitnami.com/stack/openldap

Offical docs:
The meta backend to slapd(8) performs basic LDAP proxying with respect to a set of remote LDAP servers, called "targets".
The information contained in these servers can be presented as belonging to a single Directory Information Tree (DIT).

meta proxy listens on port 1636 and maintains `dc=local,dc=blackmesa,dc=gov`
the second (remote) ldap instance is listening on 2636 and contains `dc=blackmesa,dc=gov`
one can add more instances under the same `dc=meta` umbrella

Some examples:

ldapsearch -x -H ldaps://localhost:1636 -b dc=meta

access to the meta config:

ldapvi --tls never -h ldaps://localhost:1636 -wconfig -D "cn=admin,cn=config"  -b cn=config

Access to the meta DIT:

ldapvi --tls never -h ldaps://localhost:1636 -wadminpassword -D "cn=admin,cn=config"  -b dc=meta

Access to the remote instance

ldapsearch  -LLL -x -H ldaps://localhost:2636   -b dc=blackmesa,dc=gov

Adding a new remote:

ldapadd -H ldaps://localhost:1636 -D "cn=admin,cn=config" -wconfig -f remote.ldif

cat remote.ldif
```
dn: olcMetaSub={2}uri,olcDatabase={3}meta,cn=config
objectClass: olcMetaTargetConfig
olcMetaSub: {2}uri
olcDbURI: "ldaps://<remote_host>:636/<orig_dc>,dc=meta"
olcDbRewrite: {0}suffixmassage "<orig_dc>,dc=meta" "<orig_dc>"
olcDbRebindAsUser: FALSE
olcDbStartTLS: start starttls=no tls_reqcert=never
```

Makefile options:

 * make initdemo - start demo
 * make purge_all - stop and destroy containers
 * make cleanstate - remove openldap data
 * make start; make stop; - docker compose up and down with -d option
