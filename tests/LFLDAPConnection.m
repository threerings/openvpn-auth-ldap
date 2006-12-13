/*
 * LFLDAPConnection.m
 * LFLDAPConnection Unit Tests
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
#include <src/LFLDAPConnection.h>

#include <check.h>
#include <string.h>

#include "tests.h"

/* Data Constants */
#define TEST_LDAP_URL	"ldap://ldap1.example.org"
#define TEST_LDAP_TIMEOUT	15

START_TEST(test_init) {
	LFAuthLDAPConfig *config;
	LFLDAPConnection *conn;
	LFString *value;

	config = [[LFAuthLDAPConfig alloc] initWithConfigFile: AUTH_LDAP_CONF];
	fail_if(config == NULL, "-[[LFAuthLDAPConfig alloc] initWithConfigFile:] returned NULL");

	conn = [[LFLDAPConnection alloc] initWithURL: [config url] timeout: [config timeout]];

	/* Referrals */
	fail_unless([conn setReferralEnabled: [config referralEnabled]]);

	/* Certificate file */
	if ((value = [config tlsCACertFile]))
		fail_unless([conn setTLSCACertFile: value]);

	/* Certificate directory */
	if ((value = [config tlsCACertDir]))
		fail_unless([conn setTLSCACertDir: value]);

	/* Client Certificate Pair */
	if ([config tlsCertFile] && [config tlsKeyFile])
		fail_unless([conn setTLSClientCert: [config tlsCertFile] keyFile: [config tlsKeyFile]]);

	/* Cipher suite */
	if ((value = [config tlsCipherSuite]))
		fail_unless([conn setTLSCipherSuite: value]);

	[config release];
	[conn release];
}
END_TEST

Suite *LFLDAPConnection_suite(void) {
	Suite *s = suite_create("LFLDAPConnection");

	TCase *tc_ldap = tcase_create("LDAP");
	suite_add_tcase(s, tc_ldap);
	tcase_add_test(tc_ldap, test_init);

	return s;
}
