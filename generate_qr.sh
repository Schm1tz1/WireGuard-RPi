#!/usr/bin/env bash
if [[ -z $1 ]]; then
	echo "Usage: $0 <configuration file (.config)>"
	exit 1
fi

qrencode -t ansiutf8 < $1
