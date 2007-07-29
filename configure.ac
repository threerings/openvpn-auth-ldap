AC_PREREQ(2.57)
AC_INIT(auth-ldap, [2.0], landonf@opendarwin.org)
AC_CONFIG_SRCDIR(${srcdir}/src/auth-ldap.m)
AC_CONFIG_HEADERS(config.h)

AC_CANONICAL_SYSTEM

# Compiler
AC_PROG_CC
AC_PROG_OBJC
TR_WERROR
AC_CACHE_SAVE

# Programs
AC_PROG_INSTALL
AC_PROG_LN_S
AC_PROG_MAKE_SET

AC_CHECK_TOOL(RANLIB, ranlib, :)
AC_CHECK_TOOL(AR, ar, :)

AC_PATH_PROG([RE2C], [re2c], [no])
if test x"$RE2C" = x"no"; then
	AC_MSG_ERROR([re2c was not found in your PATH. It can be downloaded from http://re2c.org])
fi

AC_PATH_PROG([DOXYGEN], [doxygen], [no])
if test x"$DOXYGEN" = x"no"; then
	DOXYGEN="false"
fi

AC_PATH_PROG([DOT], [dot], [no])
if test x"$DOT" = x"no"; then
	DOTDIR=""
else
	DOTDIR=`AS_DIRNAME([$DOT])`
fi
AC_SUBST([DOTDIR])
AC_CACHE_SAVE

# Headers
AC_HEADER_STDC
AC_CACHE_SAVE

# Threads
ACX_PTHREAD
AC_CACHE_SAVE

# Platform
OD_CONFIG_PLUGIN
TR_PF_IOCTL
AC_CACHE_SAVE

# Functions
AC_CHECK_FUNCS([strlcpy])
AC_CACHE_SAVE

# Libraries
OD_OPENLDAP
TR_OPENSSL
AC_CACHE_SAVE

# Unit Testing
OD_LIBCHECK
TR_BUILD_APACHEDS

# OpenVPN
OD_OPENVPN_HEADER
AC_CACHE_SAVE

# Objective-C Runtime
OD_OBJC_RUNTIME
AC_CACHE_SAVE

# Output
AC_CONFIG_FILES([
	Makefile

	docs/Makefile
	docs/doxyfile

	Mk/autoconf.mk
	Mk/compile.mk
	Mk/subdir.mk

	src/Makefile
	src/config/Makefile
	src/ldap/Makefile
	src/pf/Makefile
	src/util/Makefile

	tests/Makefile
	tests/apacheds/Makefile
	tests/config/Makefile
	tests/ldap/Makefile
	tests/pf/Makefile
	tests/util/Makefile

	tools/Makefile
])
AC_OUTPUT
