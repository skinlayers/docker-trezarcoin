#!/bin/bash
set -e

if [ ! -d /data/.trezarcoin ]; then
    mkdir -m 0700 /data/.trezarcoin
fi

p2 -t /trezarcoin.conf.p2 > /data/.trezarcoin/trezarcoin.conf
chmod 0600 /data/.trezarcoin/trezarcoin.conf

# if command starts with an option, prepend trezarcoind
if [ "${1:0:1}" = '-' ]; then
    set -- /usr/local/bin/trezarcoind "$@"
fi

exec "$@"
