#!/bin/bash

source ./helper.sh

export NEOGO_LOG=./neo-go.deploy.log

[[ $# -ne 2 ]] && die "Usage: $0 <new-neofs-adm> <new-contracts>"

neo-go::stop || die "Can't stop neo-go node."

make clean
make build NEOFS_CONTRACT_BRANCH="$0" NEOFS_BRANCH="$1" || die "Can't build contracts or neofs-adm."

wallet::generate || die "Can't generate wallet."

neo-go::start || die "Can't start neo-go node."
trap -- neo-go::stop EXIT

contract::deploy || die "Error during contract deploy."

# Check that hashes from NNS are correctly set.
contract::check_hashes

adm::force-new-epoch || die "Can't force new epoch."
