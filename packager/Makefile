PWD:=$(shell pwd)
AWS=$(shell which aws)
FPM=$(shell which fpm)
UNZIP=$(shell which unzip)
WGET=$(shell which wget)
CREATEREPO=$(shell which createrepo)

BINDIR:=/usr/bin
DATADIR:=/var/lib/consul
DOWNLOADDIR:=/tmp/consul-$(CONSUL_VERSION)
CONSUL_SERVER_LOCAL_REPO:=consul/server/centos/6/x86_64
CONSUL_SERVER_S3_PATH:=s3://$(S3_REPO_BUCKET)/consul/server
CONSUL_VERSION?=0.6.3
CONSUL_TEMPLATE_VERSION?=0.12.2

S3_REPO_BUCKET?=my-consul-s3-repo-bucket

RPM_USER:=nobody
RPM_GROUP:=nobody

.PHONY: all
all:
	@echo "Usage :"
	@echo "make consul_server_build"
	@exit 1

.PHONY: consul_server_build
consul_server_build: prepare consul_download \
	consul_server_sync_from_s3 \
	consul_server_package \
	consul_server_createrepo \
	consul_server_sync_to_s3

.PHONY: prepare
prepare: clean consul_prepare_build_dirs

.PHONY: clean
clean:
	rm -rf consul
	rm -rf consul-template

.PHONY: consul_prepare_build_dirs
consul_prepare_build_dirs:
	# to build the package
	mkdir -p consul/tmp/server/{usr/bin,var/lib/consul,etc/init,etc/consul.d/server}
	# to create the repo
	mkdir -p consul/server/centos/6/x86_64

.PHONY: consul_server_sync_from_s3
consul_server_sync_from_s3:
	$(AWS) s3 sync $(CONSUL_SERVER_S3_PATH) ./consul/server

.PHONY: consul_download
consul_download:
	mkdir -p $(DOWNLOADDIR)
	[ -f $(DOWNLOADDIR)/consul.zip ] || $(WGET) -q https://releases.hashicorp.com/consul/$(CONSUL_VERSION)/consul_$(CONSUL_VERSION)_linux_amd64.zip -O $(DOWNLOADDIR)/consul.zip
	$(UNZIP) -n $(DOWNLOADDIR)/consul.zip -d $(DOWNLOADDIR)
	chmod +x $(DOWNLOADDIR)/consul

.PHONY: consul_server_package
consul_server_package:
	cp $(DOWNLOADDIR)/consul consul/tmp/server/usr/bin/
	cp support/config/upstart/consul-server.conf consul/tmp/server/etc/init/consul-server.conf
	cp support/config/upstart/consul-join.conf consul/tmp/server/etc/init/consul-join.conf

	$(FPM) \
		-f \
		-n consul-server \
		-t rpm \
		-s dir \
		-C consul/tmp/server \
		--package $(CONSUL_SERVER_LOCAL_REPO) \
		--version $(CONSUL_VERSION) \
		--architecture x86_64 \
		--prefix / \
		--description "consul in server mode" \
		--rpm-user $(RPM_USER) \
		--rpm-group $(RPM_GROUP) \
		--rpm-os linux

.PHONY: consul_server_createrepo
consul_server_createrepo:
	$(CREATEREPO) $(CONSUL_SERVER_LOCAL_REPO)

.PHONY: consul_server_sync_to_s3
consul_server_sync_to_s3:
	$(AWS) s3 sync ./consul/server $(CONSUL_SERVER_S3_PATH)
