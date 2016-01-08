#!/usr/bin/env bash
/etc/init.d/nginx stop
/root/letsencrypt/letsencrypt-auto certonly --standalone -d $(cat /etc/ansible/cozy-vars.yml | grep cozy_domain |cut -d"'" -f2) --standalone-supported-challenges tls-sni-01 --renew-by-default
/etc/init.d/nginx start
