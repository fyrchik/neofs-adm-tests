#!/bin/bash

NEOGO_BIN=./neo-go/bin/neo-go
NEOGO_LOG=${NEOGO_LOG:-./neo-go.log}
NEOFSADM_BIN=./neofs-node/bin/neofs-adm

pidfile=neo-go.pid
rpc_addr=http://127.0.0.1:20331

die() {
	echo "$*"
	exit 1
}

neo-go::start() {
	"${NEOGO_BIN}" node --privnet --debug --config-path=. >"${NEOGO_LOG}" 2>&1 &
	echo $! >$pidfile
	for i in $(seq 1 20); do
		"${NEOGO_BIN}" query height -r ${rpc_addr} && return
		[[ $i -eq 5 ]] || sleep 0.1s
	done
	die "Failed to start neo-go node in 2 seconds."
}

neo-go::stop() {
	if ps -p "$(cat $pidfile)" >/dev/null; then
		kill -9 "$(cat $pidfile)"
	fi
}

wallet::generate() {
	mkdir -p wallets
	"${NEOFSADM_BIN}" morph generate-alphabet -c neofs-adm.yml --size 1
	pub="$(neo-go/bin/neo-go wallet dump-keys -w wallets/az.json | sed -n 2p)"
	sed "/StandbyCommittee/ {n;s|- .*|- $pub|;}" protocol.privnet.yml.tmpl >protocol.privnet.yml
}

contract::deploy() {
	"${NEOFSADM_BIN}" morph init -c neofs-adm.yml \
		-r ${rpc_addr} --contracts ./neofs-contract
}

contract::update() {
	"${NEOFSADM_BIN}" morph update-contracts -c neofs-adm.yml \
		-r ${rpc_addr} --contracts ./neofs-contract
}

contract::hashes() {
	"${NEOFSADM_BIN}" morph dump-hashes -r ${rpc_addr} 2>&1
}

contract::version() {
	"${NEOGO_BIN}" contract testinvokefunction -r ${rpc_addr} "$1" version
}

contract::check_hashes() {
	# Usually the name is just a word but for alphabet contracts we use 'alphabet <number>'
	local name_pat='([[:alpha:]]+([[:space:]]*[[:digit:]]+)?)'
	local hash_pat='[[:space:]]+([[:digit:][:alpha:]]+)'
	while read -r line; do
		[[ $line =~ ${name_pat}[^:]*\:${hash_pat} ]] ||
			die "Invalid output for dump-hashes: '$line'."
		name="${BASH_REMATCH[1]}"
		hash="${BASH_REMATCH[3]}"
		contract::version "$hash" | grep HALT >/dev/null || die "Can't fetch contract version for $name."
		echo "ok - fetch version for '$name' at $hash"
	done < <(contract::hashes)
}
