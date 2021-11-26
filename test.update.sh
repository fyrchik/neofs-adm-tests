#!/bin/bash

source ./helper.sh

export NEOGO_LOG=./neo-go.update.log

[[ $# -lt 4 ]] && die "Usage: $0 <old-neofs-adm> <old-contracts> <new-neofs-adm> <new-contracts> [<old-neo-go> <new-neo-go]"

neo-go::stop || die "Can't stop neo-go node."

make clean
make build NEOGO_BRANCH="${5:master}" NEOFS_BRANCH="$1" CONTRACT_BRANCH="$2" || die "Can't build contracts or neofs-adm."

wallet::generate || die "Can't generate wallet."

# We don't restart neo-go so newest version should run.
[[ -z $5 || $5 == master ]] || make build.neo-go NEOGO_BRANCH="${6:master}"
neo-go::start || die "Can't start neo-go node."
trap -- neo-go::stop EXIT

contract::deploy || die "Error during contract deploy."

make build NEOFS_BRANCH="$3" CONTRACT_BRANCH="$4" || die "Can't build contracts or neofs-adm."

contract::update || die "Error during contract update."

contract::check_hashes
