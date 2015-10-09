#!/usr/bin/env bash

export RAILGUN_DATABASE=postgres://railgun_network:WsBhuu7Q5EjjgfD7Sjb7BKhP@postgres.lv5.ac/railgun

# addresses
wget -O GeoLite2-Country-CSV.zip http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country-CSV.zip
unzip -j -o -d GeoLite2-Country-CSV GeoLite2-Country-CSV.zip
ruby addresses.rb

# proxy
curl -k -u admin:e2vAYdr3w5TPfLnun98G2zED https://localhost:8089/servicesNS/admin/search/search/jobs/export -d output_mode=raw -d search='search host=railgun8 source="/var/log/squid/access.log"' | ruby proxy.rb | cat - templates/proxy.template | uglifyjs - --compress --mangle  > ../views/proxy.hjs

# openvpn
list=$(ruby openvpn.rb)
count=$(echo ${list} | wc -l) list=${list} envsubst < templates/openvpn.template > ../views/openvpn.hjs