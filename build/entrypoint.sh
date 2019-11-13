#!/bin/sh

##################
# v0.2.0 migration
##################
if [ ! -f /etc/bind/dappnode.hosts ]; then
    cp /config/dappnode.hosts /etc/bind/dappnode.hosts
fi

##################
# v0.2.1 migration
##################
if [ ! -f /etc/bind/dappnode.io.hosts ]; then
    cp /config/dappnode.io.hosts /etc/bind/dappnode.io.hosts
fi

if [ ! -f /etc/bind/default.hosts ]; then
    cp /config/default.hosts /etc/bind/default.hosts
fi

if [ ! -f /etc/bind/test.hosts ]; then
    cp /config/test.hosts /etc/bind/test.hosts
fi

diff /etc/bind/named.conf /config/named.conf
if [ $? -ne 0 ]; then
    cp /config/named.conf /etc/bind/named.conf
fi

supervisord