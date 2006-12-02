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

#include "tests.h"

/* Data Constants */
#define TEST_LDAP_URL	"ldap://ldap1.example.org"
#define TEST_LDAP_TIMEOUT	15

START_TEST (test_initWithConfigFile) {
	LFAuthLDAPConfig *config;
	LFString *string;

	config = [[LFAuthLDAPConfig alloc] initWithConfigFile: AUTH_LDAP_CONF];
	fail_if(config == NULL, "-[[LFAuthLDAPConfig alloc] initWithConfigFile:] returned NULL");

	/* Validate the parsed settings */
	string = [config url];
	fail_if(!string, "-[LFAuthLDAPConfig url] returned NULL");
	fail_unless(strcmp([string cString], TEST_LDAP_URL) == 0, "-[LFAuthLDAPConfig url] returned incorrect value. (Expected %s, Got %s)", TEST_LDAP_URL, [string cString]);

	fail_unless([config timeout] == TEST_LDAP_TIMEOUT);

	fail_unless([config tlsEnabled]);

	fail_if([config ldapGroups] == nil);
	fail_if([[config ldapGroups] lastObject] == nil);

#ifdef HAVE_PF
	fail_unless([config pfEnabled]);
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

START_TEST (test_initWithMismatchedSection) {
	LFAuthLDAPConfig *config;

	config = [[LFAuthLDAPConfig alloc] initWithConfigFile: AUTH_LDAP_CONF_MISMATCHED];
	fail_if(config != NULL, "-[[LFAuthLDAPConfig alloc] initWithConfigFile:] accepted a mismatched section closure.");

	[config release];
}
END_TEST

START_TEST (test_initWithDuplicateKeys) {
	LFAuthLDAPConfig *config;

	config = [[LFAuthLDAPConfig alloc] initWithConfigFile: AUTH_LDAP_CONF_MULTIKEY];
	fail_if(config != NULL, "-[[LFAuthLDAPConfig alloc] initWithConfigFile:] accepted duplicate keys.");

	[config release];
}
END_TEST

START_TEST (test_initWithMissingKey) {
	LFAuthLDAPConfig *config;

	config = [[LFAuthLDAPConfig alloc] initWithConfigFile: AUTH_LDAP_CONF_REQUIRED];
	fail_if(config != NULL, "-[[LFAuthLDAPConfig alloc] initWithConfigFile:] accepted a missing required key.");

	[config release];
}
END_TEST

Suite *LFAuthLDAPConfig_suite(void) {
	Suite *s = suite_create("LFAuthLDAPConfig");

	TCase *tc_parse = tcase_create("Parse Configuration");
	suite_add_tcase(s, tc_parse);
	tcase_add_test(tc_parse, test_initWithConfigFile);
	tcase_add_test(tc_parse, test_initWithIncorrectlyNamedSection);
	tcase_add_test(tc_parse, test_initWithMismatchedSection);
	tcase_add_test(tc_parse, test_initWithDuplicateKeys);
	tcase_add_test(tc_parse, test_initWithMissingKey);

	return s;
}
