#
# Build the OpenVPN auth-ldap module.
#

# This directory is where we will look for openvpn-plugin.h
OPENVPN?=	/usr/local/src/openvpn-2.0_rc17
LDAP?=		/usr/local/

INCLUDE=	-I$(OPENVPN) -I$(LDAP)/include -I.
LDFLAGS=	-L$(LDAP)/lib

CFLAGS=		-g -O2 -Wall -fPIC $(INCLUDE)
OBJCFLAGS=	$(CFLAGS) -fno-strict-aliasing
LIBS=		-lldap -lobjc -lpthread
OBJS=		auth-ldap.o LFString.o LFLDAPConnection.o LFAuthLDAPConfig.o
TEST_OBJS=	$(OBJS) test.o

# For GNU make.
.SUFFIXES: .m .c

.m.o:
	gcc -c $< -o $@ ${OBJCFLAGS}
.c.o:
	gcc -c $< -o $@ ${CFLAGS}

openvpn-auth-ldap.so : $(OBJS)
	gcc ${CFLAGS} -fPIC -shared -Wl,-soname,$@ -o $@ $(OBJS) $(LIBS) $(LDFLAGS)

.PHONY: test
test: $(TEST_OBJS) openvpn-auth-ldap.so
	gcc -o $@ $(TEST_OBJS) $(LIBS) $(LDFLAGS)
	./test

clean :
	rm -f $(TEST_OBJS) $(OBJS) openvpn-auth-ldap.so test
