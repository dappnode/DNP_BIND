#!/bin/sh

if [ ! -f /etc/bind/dappnode.hosts ]; then
    cp /config/dappnode.hosts /etc/bind/dappnode.hosts
fi

if [ ! -f /etc/bind/dappnode.io.hosts ]; then
    cp /config/dappnode.io.hosts /etc/bind/dappnode.io.hosts
fi

if [ ! -f /etc/bind/default.hosts ]; then
    cp /config/default.hosts /etc/bind/default.hosts
fi

cp /config/eth.static.hosts /etc/bind/eth.static.hosts
cp /config/eth.hosts /etc/bind/eth.hosts

diff /etc/bind/named.conf /config/named.conf
if [ $? -ne 0 ]; then
    cp /config/named.conf /etc/bind/named.conf
fi

exec supervisord
