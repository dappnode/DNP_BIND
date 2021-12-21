#!/bin/sh

# Clean up old files
rm -f /etc/bind/*.hosts
rm -f /etc/bind/*.jnl
 
echo "copying hosts/config"
cp /config/*.hosts /etc/bind/
cp /config/named.conf /etc/bind/named.conf

supervisord -c /supervisord.conf