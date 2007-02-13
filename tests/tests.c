/*
 * tests.c
 * OpenVPN LDAP Authentication Plugin Unit Tests
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

#include <config.h>

#include <stdlib.h>
#include <unistd.h>
#include <check.h>
#include <stdio.h>

#include <tests.h>

void print_usage(const char *name) {
	printf("Usage: %s [filename]\n", name);
	printf(" [filename]\tWrite XML log to <filename>\n");
}

int main(int argc, char *argv[]) {
	Suite *s;
	SRunner *sr;
	int nf;

	if (argc > 2) {
		print_usage(argv[0]);
		exit(1);
	}

	/* Load all test suites */
	s = LFString_suite();
	sr = srunner_create(s);
	srunner_add_suite(sr, LFAuthLDAPConfig_suite());
	srunner_add_suite(sr, LFLDAPConnection_suite());
	srunner_add_suite(sr, TRLDAPEntry_suite());
	srunner_add_suite(sr, TRObject_suite());
	srunner_add_suite(sr, TRArray_suite());
	srunner_add_suite(sr, TRHash_suite());
	srunner_add_suite(sr, TRConfigToken_suite());
	srunner_add_suite(sr, TRConfigLexer_suite());
	srunner_add_suite(sr, TRConfig_suite());
	srunner_add_suite(sr, TRLDAPGroupConfig_suite());
#ifdef HAVE_PF
	srunner_add_suite(sr, TRPacketFilter_suite());
	srunner_add_suite(sr, TRPFAddress_suite());
#endif

	/* Enable XML output */
	if (argc == 2)
		srunner_set_xml(sr, argv[1]);

	/* Run tests */
	srunner_run_all(sr, CK_NORMAL);

	nf = srunner_ntests_failed(sr);
	srunner_free(sr);

	if (nf == 0)
		exit(EXIT_SUCCESS);
	else
		exit(EXIT_FAILURE);
}
