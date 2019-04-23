#!/bin/sh

##################
# v0.2.0 migration
##################
if [ ! -f /etc/bind/dappnode.hosts ]; then
    cp /config/dappnode.hosts /etc/bind/dappnode.hosts
fi

diff /etc/bind/named.conf /config/named.conf
if [ $? -ne 0 ]; then
    cp /config/named.conf /etc/bind/named.conf
fi

supervisord