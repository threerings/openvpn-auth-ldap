/*
 * LFAuthLDAPConfig.m
 * LFAuthLDAPConfig Unit Tests
 *
 * Author: Landon Fuller <landonf@threerings.net>
 *
 * Copyright (c) 2006 Three Rings Design, Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of Landon Fuller nor the names of any contributors
 *    may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <src/LFAuthLDAPConfig.h>

#include <check.h>
#include <string.h>

/* Data Constants */
#define LDAP_URL	"ldap://ldap1.example.org"

/* Path Constants */
#define DATA_PATH(relative)	TEST_DATA "/" relative
#define AUTH_LDAP_CONF		DATA_PATH("auth-ldap.conf")
#define AUTH_LDAP_CONF_NAMED	DATA_PATH("auth-ldap-named.conf")

START_TEST (test_initWithConfigFile) {
	LFAuthLDAPConfig *config;
	// const char *url;

	config = [[LFAuthLDAPConfig alloc] initWithConfigFile: AUTH_LDAP_CONF];
	fail_if(config == NULL, "-[[LFAuthLDAPConfig alloc] initWithConfigFile:] returned NULL");

#if 0
	url = [config url];

	fail_if(!url, "-[LFAuthLDAPConfig url] returned NULL");
	fail_unless(strcmp(url, LDAP_URL) == 0, "-[LFAuthLDAPConfig url] returned incorrect value. (Expected %s, Got %s)", LDAP_URL, url);
#endif

	[config release];
}
END_TEST

START_TEST (test_initWithIncorrectlyNamedSection) {
	LFAuthLDAPConfig *config;

	config = [[LFAuthLDAPConfig alloc] initWithConfigFile: AUTH_LDAP_CONF_NAMED];
	fail_if(config != NULL, "-[[LFAuthLDAPConfig alloc] initWithConfigFile:] accepted a named LDAP section.");

	[config release];
}
END_TEST




Suite *LFAuthLDAPConfig_suite(void) {
	Suite *s = suite_create("LFAuthLDAPConfig");

	TCase *tc_parse = tcase_create("Parse Configuration");
	suite_add_tcase(s, tc_parse);
	tcase_add_test(tc_parse, test_initWithConfigFile);
	tcase_add_test(tc_parse, test_initWithIncorrectlyNamedSection);

	return s;
}
