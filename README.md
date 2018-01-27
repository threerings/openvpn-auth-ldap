## Description

The OpenVPN Auth-LDAP Plugin implements username/password authentication via LDAP for OpenVPN 2.x.

### Features
  * User authentication against LDAP.
  * Simple Apache-style configuration file.
  * LDAP group-based access restrictions.
  * Integration with the OpenBSD packet filter, supporting adding and removing VPN clients from PF tables based on group membership.
  * Tested against OpenLDAP, the plugin will authenticate against any LDAP server that supports LDAP simple binds -- including Active Directory.
  * Supports OpenVPN Challenge/Response protocol, enabling it to be used in combination with one time password systems like Google Authenticator

## Building

### Requirements

  * OpenLDAP Headers and Library
  * GNU Objective-C Compiler
  * OpenVPN Plugin Header (included with the OpenVPN sources)
  * [re2c](http://www.re2c.org/) (used for the configuration file lexer)

To build, you will need to configure the sources appropriately. Example:

```
./configure --prefix=/usr/local --with-openldap=/usr/local --with-openvpn=/home/sean/work/openvpn-2.0.2
```

The module will be built in src/openvpn-auth-ldap.so and installed as
`${prefix}/lib/openvpn-auth-ldap.so`.

#### Building On Ubuntu 16.04 ####

The following steps were tested on a clean Ubuntu 16.04 LTS Amazon EC2 m5.large instance in January 2018 (source AMI: ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-20180109 - ami-41e0b93b).

If you wish to repeat this process, follow these steps on your own machine:

```
git clone https://github.com/snowrider311/openvpn-auth-ldap
cd openvpn-auth-ldap/
./ubuntu_16.04_lts_build.sh
```

The `ubuntu_16.04_lts_build.sh` script will install all needed build dependencies, perform the build, and install `openvpn-auth-ldap.so` to `/usr/local/lib`.

If you then wish to create a Debian package, you can then run this script:

```
./ubuntu_16.04_lts_package.sh
```

That script will install [FPM](https://github.com/jordansissel/fpm) and then use it to build a Debian package. If you then run `sudo dpkg -i openvpn-auth-ldap-snowrider311_2.0.3-1_amd64.deb`, then `openvpn-auth-ldap.so` will be installed to `/usr/lib/openvpn`, the same location as the standard, unforked `openvpn-auth-ldap` Debian package installs to. 

Note: Superuser privileges are required to run these scripts.

If you just want the Debian package, it's checked into this repository ([direct link](https://github.com/snowrider311/openvpn-auth-ldap/blob/master/openvpn-auth-ldap-snowrider311_2.0.3-1_amd64.deb)).

## Usage

Add the following to your OpenVPN configuration file (adjusting the plugin path as required):

```
plugin /usr/local/lib/openvpn-auth-ldap.so "<config>"
```

The config directive must point to an auth-ldap configuration file. An example configuration file
is provided with the distribution, or see the [Configuration](../../wiki/Configuration) page.


## Security

*Please report all security issues directly to landonf+security (at) bikemonkey (dot) org.*

Through the use of extensive unit testing, valgrind, and regression testing, we are very confident
in the overall code quality of the plugin. There has been one security vulnerability to date, due
to misinterpretation of LDAP RFCs.

  * 2006-12-02: OpenVPN Auth-LDAP would accept empty passwords when validating against Novell Directory Server. This is known to not affect default installs of OpenLDAP (our test platform). Strict implementation of the LDAP RFCs requires that a directory server treat a bind with a valid DN and an empty password as an "anonymous" bind. If anonymous binds are enabled, this could lead to password bypass.

## Support

Plausible Labs Cooperative is available to provide custom development or support for this plugin.
If you require specific features or additions, please [contact
us](http://www.plausible.coop/about/) for more information.
