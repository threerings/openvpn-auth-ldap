## Description ##

The OpenVPN Auth-LDAP Plugin implements username/password authentication via LDAP for OpenVPN 2.x.

### Features ###
  * User authentication against LDAP.
  * Simple Apache-style configuration file.
  * LDAP group-based access restrictions.
  * Integration with the OpenBSD packet filter, supporting adding and removing VPN clients from PF tables based on group membership.
  * Tested against OpenLDAP, the plugin will authenticate against any LDAP server that supports LDAP simple binds -- including Active Directory.

## Building ##

### Requirements ###

  * OpenLDAP Headers and Library
  * GNU Objective-C Compiler
  * OpenVPN Plugin Header (included with the OpenVPN sources)
  * [re2c](http://www.re2c.org/) (used for the configuration file lexer)

To build, you will need to configure the sources appropriately. Example:

```
./configure --prefix=/usr/local --with-openldap=/usr/local --with-openvpn=/usr/ports/security/openvpn/work/openvpn-2.0.2
```

The module will be build in src/openvpn-auth-ldap.so and installed as ${prefix}/lib/openvpn-auth-ldap.so.

## Usage ##

Add the following to your OpenVPN configuration file (adjusting the plugin path as required):

```
plugin /usr/local/lib/openvpn-auth-ldap.so "<config>"
```

The config directive must point to an auth-ldap configuration file. An example configuration file is provided with the distribution, or see the [Configuration](Configuration.md) page.


## Security ##

**Please report all security issues directly to landonf+security (at) bikemonkey (dot) org.**

Through the use of extensive unit testing, valgrind, and regression testing, we are very confident in the overall code quality of the plugin. There has been one security vulnerability to date, due to misinterpretation of LDAP RFCs.

  * 2006-12-02: OpenVPN Auth-LDAP would accept empty passwords when validating against Novell Directory Server. This is known to not affect default installs of OpenLDAP (our test platform). Strict implementation of the LDAP RFCs requires that a directory server treat a bind with a valid DN and an empty password as an "anonymous" bind. If anonymous binds are enabled, this could lead to password bypass.

## Support ##

Plausible Labs Cooperative is available to provide custom development or support for this plugin. If you require specific features or additions, please [contact us](http://www.plausible.coop/about/) for more information.