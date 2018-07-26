#! /bin/bash

sudo apt-get install -y ruby ruby-dev rubygems build-essential
sudo gem install --no-ri --no-rdoc fpm

mkdir -p /tmp/openvpn-auth-ldap-build/usr/lib/openvpn
sudo mv /usr/local/lib/openvpn-auth-ldap.so /tmp/openvpn-auth-ldap-build/usr/lib/openvpn
fpm -s dir -C /tmp/openvpn-auth-ldap-build -t deb --name openvpn-auth-ldap-snowrider311 \
  --version 2.0.3 --iteration 1 --depends openvpn --depends gnustep-base-runtime \
  --depends libc6 --depends libgnustep-base1.24 --depends libldap-2.4-2 --depends libobjc4

# To install:
# sudo dpkg -i openvpn-auth-ldap-snowrider311_2.0.3-1_amd64.deb
