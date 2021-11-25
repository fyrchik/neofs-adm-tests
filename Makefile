NEOGO_ORIGIN = https://github.com/nspcc-dev/neo-go.git
NEOGO_BRANCH ?= master
NEOGO_BIN = ./neo-go/bin/neo-go

NEOFS_ORIGIN = https://github.com/nspcc-dev/neofs-node.git
NEOFS_REPO ?= $(NEOFS_ORIGIN)
NEOFS_BRANCH ?= master
NEOFS_BIN = ./neofs-node/bin/neofs-adm

CONTRACT_ORIGIN = https://github.com/nspcc-dev/neofs-contract.git
CONTRACT_REPO ?= $(CONTRACT_ORIGIN)
CONTRACT_BRANCH ?= master

NEOGO_PIDFILE = neo-go.pid

.PHONY: clone
clone:
ifeq (,$(wildcard ./neo-go))
	git clone $(NEOGO_ORIGIN) neo-go
endif
ifeq (,$(wildcard ./neofs-node))
	git clone $(NEOFS_ORIGIN) neofs-node
endif
ifeq (,$(wildcard ./neofs-contract))
	git clone $(CONTRACT_ORIGIN) neofs-contract
endif

.PHONY: build build.contracts build.neo-go build.neofs-adm
build: build.neo-go build.contracts build.neofs-adm

build.neo-go:
	cd neo-go && git checkout $(NEOGO_BRANCH) && $(MAKE) -B build

build.neofs-adm:
ifneq ($(NEOFS_ORIGIN),$(NEOFS_REPO))
	cd neofs-node && git remote add custom $(NEOFS_REPO) && git fetch custom --tags
endif
	cd neofs-node && git checkout $(NEOFS_BRANCH) && $(MAKE) -B bin/neofs-adm

build.contracts:
ifneq ($(CONTRACT_ORIGIN),$(CONTRACT_REPO))
	cd neofs-contract && git remote add custom $(CONTRACT_REPO) && git fetch custom --tags
endif
	cd neofs-contract && git checkout $(CONTRACT_BRANCH) && NEOGO=../$(NEOGO_BIN) $(MAKE) -B all

.PHONY: clean
clean:
	rm -rf ./chains
	rm -rf ./wallets