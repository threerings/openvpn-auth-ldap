#------------------------------------------------------------------------
# OD_LIBCHECK --
#
#       Decipher the correct ldflags and cflags to link against libcheck
#
# Arguments:
#       None.
#
# Requires:
#       None.
#
# Depends:
#	AC_PROG_CC
#
# Results:
#
#       Adds the following arguments to configure:
#               --with-libcheck switch to configure.
#
#       Result is cached.
#
#	Defines and substitutes the following vars:
#               LIBCHECK_CFLAGS
#               LIBCHECK_LIBS
#
#------------------------------------------------------------------------

dnl Test for check, and define CHECK_CFLAGS and CHECK_LIBS
dnl

AC_DEFUN(OD_LIBCHECK, [
	AC_ARG_WITH(check, AC_HELP_STRING([--with-check=PATH], [Prefix where check unit test library is installed. Defaults to auto-detection]), [with_libcheck_prefix=${withval}])

	if test x"${with_libcheck_prefix}" != x; then
		CHECK_CFLAGS="-I$with_check/include"
		CHECK_LIBS="-L$with_check/lib -lcheck"
	else
		CHECK_CFLAGS=""
		CHECK_LIBS="-lcheck"
	fi

	AC_MSG_CHECKING([for check unit test library])

	AC_CACHE_VAL(od_cv_libcheck, [

		ac_save_CFLAGS="$CFLAGS"
		ac_save_LIBS="$LIBS"

		CFLAGS="$CFLAGS $CHECK_CFLAGS"
		LIBS="$CHECK_LIBS $LIBS"
		
		AC_LINK_IFELSE([
			AC_LANG_PROGRAM([
					#include <check.h>
				], [
					Suite *s;
					SRunner *sr;
			])
			], [
				od_cv_libcheck="yes"
			], [
				od_cv_libcheck="no"
			]
		)

		CFLAGS="$ac_save_CFLAGS"
		LIBS="$ac_save_LIBS"

	])

	AC_MSG_RESULT(${od_cv_libcheck})

	if test x"${od_cv_libcheck}" = "xyes"; then
		CHECK_DIRS="tests"
	else
		CHECK_DIRS=""
		AC_MSG_WARN([Check library not found. Unit tests will not be built or run.])
	fi
			

	AC_SUBST(CHECK_CFLAGS)
	AC_SUBST(CHECK_LIBS)
	AC_SUBST(CHECK_DIRS)
])
