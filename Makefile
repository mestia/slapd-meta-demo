data_dirs := ldapdb_meta ldapdb_remote
cert_dirs := ldapdb_meta certs_meta certs_remote
userid    := 1001
REQBIN    := openssl ldapmodify envsubst docker
$(foreach bin,$(REQBIN),\
    $(if $(shell command -v $(bin) 2> /dev/null),,$(error `$(bin)` is missing, aborting...)))

initdemo:
	scripts/gen-certs.sh "dc=blackmesa,dc=gov,dc=meta" certs_meta
	scripts/gen-certs.sh "dc=blackmesa,dc=gov" certs_remote
	mkdir -pv ${data_dirs}
	chown -R ${userid} ${data_dirs} ${cert_dirs}
	docker compose up -d
	scripts/init_meta.sh
	docker compose down
	docker compose up -d

purge_all:
	docker compose down
	rm -rf ${cert_dirs} ${data_dirs}

cleanstate:
	rm -rf ${data_dirs}
	mkdir ${data_dirs}
	chown -R ${userid} ${data_dirs}

start:
	docker compose up -d

stop:
	docker compose down
