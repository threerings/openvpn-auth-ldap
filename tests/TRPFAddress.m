/*
 * TRPPFAddress.m
 * TRPFAddress Unit Tests
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

#ifdef HAVE_PF

#include <check.h>

#include <src/TRPFAddress.h>

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

START_TEST(test_initWithPresentationAddress) {
	LFString *addrString;
	TRPFAddress *pfAddr;
	/* Independent verification */
	struct pfr_addr *result;
	struct in_addr addr4;
	struct in6_addr addr6;

	/* Test with IPv4 */
	addrString = [[LFString alloc] initWithCString: "127.0.0.1"];
	fail_unless(inet_pton(AF_INET, "127.0.0.1", &addr4));

	pfAddr = [[TRPFAddress alloc] initWithPresentationAddress: addrString];
	[addrString release];

	/* Verify conversion */
	fail_if(pfAddr == nil);
	result = [pfAddr pfrAddr];
	fail_unless(memcmp(&result->pfra_ip4addr, &addr4, sizeof(addr4)) == 0);

	[pfAddr release];

	/* Test with IPv6 */
	addrString = [[LFString alloc] initWithCString: "::1"];
	fail_unless(inet_pton(AF_INET6, "::1", &addr6));

	pfAddr = [[TRPFAddress alloc] initWithPresentationAddress: addrString];
	[addrString release];

	/* Verify conversion */
	fail_if(pfAddr == nil);
	result = [pfAddr pfrAddr];
	fail_unless(memcmp(&result->pfra_ip6addr, &addr6, sizeof(addr6)) == 0);

	[pfAddr release];
}
END_TEST


Suite *TRPFAddress_suite(void) {
	Suite *s = suite_create("TRPFAddress");

	TCase *tc_addr = tcase_create("Address");
	suite_add_tcase(s, tc_addr);
	tcase_add_test(tc_addr, test_initWithPresentationAddress);

	return s;
}

#endif /* HAVE_PF */
