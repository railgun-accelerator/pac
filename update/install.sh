#!/usr/bin/env bash

# addresses
apt-get install -y libnet-ip-perl
wget -O aggregate-cidr-addresses.pl http://www.zwitterion.org/software/aggregate-cidr-addresses/aggregate-cidr-addresses
chmod u+x aggregate-cidr-addresses.pl
bundle install

# proxy
npm install uglify-js -g