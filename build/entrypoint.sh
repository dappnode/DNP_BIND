#!/bin/sh

##################
# v0.2.0 migration
##################
if [ ! -f /etc/bind/dappnode.hosts ]; then
    cp /config/dappnode.hosts /etc/bind/dappnode.hosts
fi
if [ ! -f /etc/bind/avado.hosts ]; then
    cp /config/avado.hosts /etc/bind/avado.hosts
fi

if [ ! -f /etc/bind/avadopackage.com.hosts ]; then
    cp /config/avadopackage.com.hosts /etc/bind/avadopackage.com.hosts
fi

if [ ! -f /etc/bind/my.ava.do.hosts ]; then
    cp /config/my.ava.do.hosts /etc/bind/my.ava.do.hosts
fi

diff /etc/bind/named.conf /config/named.conf
if [ $? -ne 0 ]; then
    cp /config/named.conf /etc/bind/named.conf
fi

supervisord