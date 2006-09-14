builtin(include,objc.m4)
builtin(include,pthread.m4)
builtin(include,platform.m4)
builtin(include,check.m4)

#------------------------------------------------------------------------
# OD_OBJC_RUNTIME --
#
#	Determine the default, working Objective C runtime
#
# Arguments:
#	None.
#
# Requires:
#	none
#
# Depends:
#	AC_PROG_OBJC from objc.m4
#
# Results:
#
#	Adds a --with-objc-runtime switch to configure.
#	Result is cached.
#
#	Defines one of the following preprocessor macros:
#		APPLE_RUNTIME GNU_RUNTIME
#
#	Substitutes the following variables:
#		OBJC_RUNTIME OBJC_RUNTIME_FLAGS OBJC_LIBS
#		OBJC_PTHREAD_CFLAGS OBJC_PTHREAD_LIBS
#------------------------------------------------------------------------
AC_DEFUN([OD_OBJC_RUNTIME],[
	AC_REQUIRE([AC_PROG_OBJC])
	AC_ARG_WITH(objc-runtime, AC_HELP_STRING([--with-objc-runtime], [Specify either "GNU" or "apple"]), [with_objc_runtime=${withval}])

	if test x"${with_objc_runtime}" != x; then
		case "${with_objc_runtime}" in
			GNU)
				;;
			apple)
				;;
			*)
				AC_MSG_ERROR([${with_objc_runtime} is not a valid argument to --with-objc-runtime. Please specify either "GNU" or "apple"])
				;;
		esac
	fi

	AC_LANG_PUSH([Objective C])

	# Check for common header, objc/objc.h
	AC_CHECK_HEADERS([objc/objc.h], ,[AC_MSG_ERROR([Can't locate Objective C runtime headers])])

	# Save LIBS & OBJCFLAGS 
	# depending on whether the cache is used,
	# the variables may or may not be modified.
	OLD_LIBS="${LIBS}"
	OLD_OBJCFLAGS="${OBJCFLAGS}"

	# Add -lobjc. The following tests will ensure that the library exists and functions with the detected Objective C compiler
	LIBS="${LIBS} -lobjc"

	# Test if pthreads are required to link against
	# libobjc - this is the case on FreeBSD.

	AC_MSG_CHECKING([if linking libobjc requires pthreads])
	AC_CACHE_VAL(od_cv_objc_req_pthread, [
		# First, test if objc links without pthreads
		# The following uses quadrigraphs
		# '@<:@' = '['
		# '@:>@' = ']'
		AC_LINK_IFELSE([
				AC_LANG_PROGRAM([
						#include <objc/objc.h>
						#include <objc/Object.h>
					], [
						Object *obj = @<:@Object alloc@:>@;
						puts(@<:@obj name@:>@);
					])
				], [
					# Linked without -pthread
					od_cv_objc_req_pthread="no"
				], [
					# Failed to link without -pthread
					od_cv_objc_req_pthread="yes"
				]
		)

		# If the above failed, try with pthreads
		if test x"${od_cv_objc_req_pthread}" = x"yes"; then
			LIBS="${LIBS} ${PTHREAD_LIBS}"
			OBJCFLAGS="${OBJCFLAGS} ${PTHREAD_CFLAGS}"
			AC_LINK_IFELSE([
					AC_LANG_PROGRAM([
							#include <objc/objc.h>
							#include <objc/Object.h>
						], [
							Object *obj = @<:@Object alloc@:>@;
							puts(@<:@obj name@:>@);
						])
					], [
						# Linked with -lpthread 
						od_cv_objc_req_pthread="yes"
					], [
						# Failed to link against objc at all
						# This will be caught in the runtime
						# checks below
						od_cv_objc_req_pthread="no"
					]
			)
		fi
	])
	AC_MSG_RESULT(${od_cv_objc_req_pthread})

	if test x"${od_cv_objc_req_pthread}" = x"no"; then
		OBJC_LIBS="-lobjc"
		OBJC_PTHREAD_LIBS="${PTHREAD_LIBS}"
		OBJC_PTHREAD_CFLAGS="${PTHREAD_CFLAGS}"
	elif test x"${od_cv_objc_req_pthread}" = x"yes"; then
		OBJC_LIBS="-lobjc ${PTHREAD_LIBS}"
		OBJCFLAGS="${OBJCFLAGS} ${PTHREAD_CFLAGS}"
	fi

	if test x"${with_objc_runtime}" = x || test x"${with_objc_runtime}" = x"apple"; then
		AC_MSG_CHECKING([for Apple Objective-C runtime])
		AC_CACHE_VAL(od_cv_objc_runtime_apple, [
			# The following uses quadrigraphs
			# '@<:@' = '['
			# '@:>@' = ']'
			AC_LINK_IFELSE([
					AC_LANG_PROGRAM([
							#include <objc/objc.h>
							#include <objc/objc-api.h>
						], [
							id class = objc_lookUpClass("Object");
							id obj = @<:@class alloc@:>@;
							puts(@<:@obj name@:>@);
						])
					], [
						od_cv_objc_runtime_apple="yes"
					], [
						od_cv_objc_runtime_apple="no"
					]
			)
		])
		AC_MSG_RESULT(${od_cv_objc_runtime_apple})
	else
		od_cv_objc_runtime_apple="no"
	fi

	if test x"${with_objc_runtime}" = x || test x"${with_objc_runtime}" = x"GNU"; then
		AC_MSG_CHECKING([for GNU Objective C runtime])
		AC_CACHE_VAL(od_cv_objc_runtime_gnu, [
			# The following uses quadrigraphs
			# '@<:@' = '['
			# '@:>@' = ']'
			AC_LINK_IFELSE([
					AC_LANG_PROGRAM([
							#include <objc/objc.h>
							#include <objc/objc-api.h>
						], [
							id class = objc_lookup_class("Object");
							id obj = @<:@class alloc@:>@;
							puts(@<:@obj name@:>@);
						])
					], [
						od_cv_objc_runtime_gnu="yes"
					], [
						od_cv_objc_runtime_gnu="no"
					]
			)
		])
		AC_MSG_RESULT(${od_cv_objc_runtime_gnu})
	else
		od_cv_objc_runtime_gnu="no"
	fi

	# Apple runtime is prefered
	if test x"${od_cv_objc_runtime_apple}" = x"yes"; then
			OBJC_RUNTIME="APPLE_RUNTIME"
			OBJC_RUNTIME_FLAGS="-fnext-runtime"
			AC_MSG_NOTICE([Using Apple Objective-C runtime])
			AC_DEFINE([APPLE_RUNTIME], 1, [Define if using the Apple Objective-C runtime and compiler.]) 
	elif test x"${od_cv_objc_runtime_gnu}" = x"yes"; then
			OBJC_RUNTIME="GNU_RUNTIME"
			OBJC_RUNTIME_FLAGS="-fgnu-runtime"
			AC_MSG_NOTICE([Using GNU Objective-C runtime])
			AC_DEFINE([GNU_RUNTIME], 1, [Define if using the GNU Objective-C runtime and compiler.]) 
	else
			AC_MSG_FAILURE([Could not locate a working Objective-C runtime.])
	fi

	# Restore LIBS & OBJCFLAGS
	LIBS="${OLD_LIBS}"
	OBJCFLAGS="${OLD_OBJCFLAGS}"

	AC_SUBST([OBJC_RUNTIME])
	AC_SUBST([OBJC_RUNTIME_FLAGS])
	AC_SUBST([OBJC_LIBS])

	AC_SUBST([OBJC_PTHREAD_LIBS])
	AC_SUBST([OBJC_PTHREAD_CFLAGS])

	AC_LANG_POP([Objective C])
])

#------------------------------------------------------------------------
# OD_OPENLDAP --
#
#	Locate the OpenLDAP libraries and headers
#
# Arguments:
#	None.
#
# Requires:
#	none
#
# Depends:
#	none
#
# Results:
#
#	Adds a --with-openldap switch to configure.
#	Result is cached.
#
#	Substitutes the following variables:
#		LDAP_LIBS LDAP_CFLAGS
#------------------------------------------------------------------------
AC_DEFUN([OD_OPENLDAP],[
	AC_REQUIRE([AC_PROG_CC])
	AC_ARG_WITH(openldap, AC_HELP_STRING([--with-openldap], [Specify the openldap installation location]), [with_openldap=${withval}])

	# Save LIBS, CFLAGS
	# depending on whether the cache is used,
	# the variables may or may not be modified.
	OLD_LIBS="${LIBS}"
	OLD_CFLAGS="${CFLAGS}"

	LDAP_LIBS="-lldap -llber"
	LDAP_CFLAGS=""

	if test x"${with_openldap}" != x; then
		LDAP_LIBS="${LDAP_LIBS} -L${with_openldap}/lib"
		LDAP_CFLAGS="${LDAP_CFLAGS} -I${with_openldap}/include"
	fi

	# Add -lldap. The following tests will ensure that the library exists and functions with the detected C compiler
	LIBS="${LIBS} ${LDAP_LIBS}"
	CFLAGS="${CFLAGS} ${LDAP_CFLAGS}"

	AC_MSG_CHECKING([for openldap])
	AC_CACHE_VAL(od_cv_openldap, [
		AC_LINK_IFELSE([
				AC_LANG_PROGRAM([
						#include <ldap.h>
					], [
						int flag = LDAP_OPT_X_TLS_NEVER;
						void *fptr = ldap_result;
					])
				], [
					# Failed
					od_cv_openldap="yes"
				], [
					# Success
					od_cv_openldap="no"
				]
		)
	])
	AC_MSG_RESULT(${od_cv_openldap})

	if test x"${od_cv_openldap}" = x"no"; then
			AC_MSG_FAILURE([Could not locate a working OpenLDAP library installation. Try --with-openldap=])
	fi

	# Restore LIBS & CFLAGS
	LIBS="${OLD_LIBS}"
	CFLAGS="${OLD_CFLAGS}"

	AC_SUBST([LDAP_CFLAGS])
	AC_SUBST([LDAP_LIBS])
])

#------------------------------------------------------------------------
# OD_OPENVPN_HEADER --
#
#	Locate the OpenVPN plugin header
#
# Arguments:
#	None.
#
# Requires:
#	none
#
# Depends:
#	none
#
# Results:
#
#	Adds a --with-openvpn switch to configure.
#	Result is cached.
#
#	Substitutes the following variables:
#		OPENVPN_CFLAGS
#------------------------------------------------------------------------
AC_DEFUN([OD_OPENVPN_HEADER],[
	AC_REQUIRE([AC_PROG_CC])
	AC_ARG_WITH(openvpn, AC_HELP_STRING([--with-openvpn], [Specify the path to the OpenVPN source]), [with_openvpn=${withval}])

	if test x"${with_openvpn}" = "x"; then
		AC_MSG_ERROR([You must specify the location of the OpenVPN source code with --with-openvpn])
	else
		OPENVPN_CFLAGS="-I${with_openvpn}"
	fi

	# Save CFLAGS
	OLD_CFLAGS="${CFLAGS}"

	CFLAGS="${CFLAGS} ${OPENVPN_CFLAGS}"

	AC_MSG_CHECKING([for openvpn-plugin.h])
	AC_CACHE_VAL(od_cv_openvpn, [
		AC_LINK_IFELSE([
				AC_LANG_PROGRAM([
						#include <openvpn-plugin.h>
					], [
						int flag = OPENVPN_PLUGIN_UP;
					])
				], [
					# Failed
					od_cv_openvpn="yes"
				], [
					# Success
					od_cv_openvpn="no"
				]
		)
	])
	AC_MSG_RESULT(${od_cv_openvpn})

	if test x"${od_cv_openvpn}" = x"no"; then
			AC_MSG_FAILURE([Could not locate a working openvpn source tree.])
	fi

	# Restore LIBS & CFLAGS
	LIBS="${OLD_LIBS}"
	CFLAGS="${OLD_CFLAGS}"

	AC_SUBST([OPENVPN_CFLAGS])
])

#------------------------------------------------------------------------
# TR_PF_IOCTL --
#
#	Locate the pf(4) headers
#
# Arguments:
#	None.
#
# Requires:
#	none
#
# Depends:
#	none
#
# Results:
#
#	Defines the following preprocessor macros:
#		OPENVPN_CFLAGS
#------------------------------------------------------------------------
AC_DEFUN([TR_PF_IOCTL],[
	AC_REQUIRE([AC_PROG_CC])

	AC_MSG_CHECKING([for BSD pf(4) support])
	AC_CACHE_VAL(tr_cv_pf_ioctl, [
		AC_LINK_IFELSE([
				AC_LANG_PROGRAM([
						#include <sys/types.h>
						#include <sys/ioctl.h>
						#include <sys/socket.h>
						#include <net/if.h>
						#include <net/pfvar.h>
					], [
						unsigned long req = DIOCRCLRTABLES;
					])
				], [
					# Failed
					tr_cv_pf_ioctl="yes"
				], [
					# Success
					tr_cv_pf_ioctl="no"
				]
		)
	])
	AC_MSG_RESULT(${tr_cv_pf_ioctl})

	if test x"${tr_cv_pf_ioctl}" = x"no"; then
			AC_MSG_WARN([pf(4) table support will not be included.])
	else
		AC_DEFINE([HAVE_PF], [1], [Define to enable pf(4) table support.])
		AC_DEFINE([PF_DEV_PATH], ["/dev/pf"], [Path to the pf(4) device.])
	fi
])

#------------------------------------------------------------------------
# TR_WERROR --
#
#	Enable -Werror
#
# Arguments:
#	None.
#
# Requires:
#	none
#
# Depends:
#	none
#
# Results:
#	Modifies CFLAGS variable.
#------------------------------------------------------------------------
AC_DEFUN([TR_WERROR],[
	AC_REQUIRE([AC_PROG_CC])
	AC_ARG_ENABLE(werror, AC_HELP_STRING([--enable-werror], [Add -Werror to CFLAGS. Used for development.]), [enable_werror=${enableval}], [enable_werror=no])
	if test x"$enable_werror" != "xno"; then
		CFLAGS="$CFLAGS -Werror"
	fi
])
