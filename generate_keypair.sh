#!/usr/bin/env bash
if [[ -z $1 ]]; then
	echo "Usage: $0 <machine name (e.g. server, client-phone etc.)>"
	exit 1
fi

wg genkey | tee $1-private.key | wg pubkey > $1-public.key
