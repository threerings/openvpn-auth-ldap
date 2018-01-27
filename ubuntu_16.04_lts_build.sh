#! /bin/bash

# git clone https://github.com/snowrider311/openvpn-auth-ldap
# cd openvpn-auth-ldap/
# source ubuntu_16.04_lts_build.sh
# source ubuntu_16.04_lts_package.sh

sudo apt-get update
sudo apt-get -y install openvpn autoconf re2c libtool libldap2-dev libssl-dev gobjc make
./regen.sh
./configure --with-openvpn=/usr/include/openvpn CFLAGS="-fPIC" OBJCFLAGS="-std=gnu11"
make
sudo make install
