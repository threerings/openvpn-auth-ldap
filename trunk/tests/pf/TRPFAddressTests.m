/*
 * TRPPFAddress.m vi:ts=4:sw=4:expandtab:
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

#include <check.h>

#include <string.h>

#include <TRVPNPlugin.h>

START_TEST(test_initWithPresentationAddress) {
    TRString *addrString;
    TRPFAddress *pfAddr;
    /* Independent verification */
    TRPortableAddress expected;
    TRPortableAddress actual;

    /* Test with IPv4 */
    addrString = [[TRString alloc] initWithCString: "127.0.0.1"];
    fail_unless(inet_pton(AF_INET, "127.0.0.1", &expected.ip4_addr));

    pfAddr = [[TRPFAddress alloc] initWithPresentationAddress: addrString];
    [addrString release];

    /* Verify conversion */
    fail_if(pfAddr == nil);
    [pfAddr address: &actual];
    fail_unless(memcmp(&actual.ip4_addr, &expected.ip4_addr, sizeof(expected.ip4_addr)) == 0);

    [pfAddr release];

    /* Test with IPv6 */
    addrString = [[TRString alloc] initWithCString: "::1"];
    fail_unless(inet_pton(AF_INET6, "::1", &expected.ip6_addr));

    pfAddr = [[TRPFAddress alloc] initWithPresentationAddress: addrString];
    [addrString release];

    /* Verify conversion */
    fail_if(pfAddr == nil);
    [pfAddr address: &actual];
    fail_unless(memcmp(&actual.ip6_addr, &expected.ip6_addr, sizeof(expected.ip6_addr)) == 0);

    [pfAddr release];
}
END_TEST

START_TEST(test_initWithPortableAddress) {
    TRString *addrString;
    TRPFAddress *pfAddr;
    TRPortableAddress expected;
    TRPortableAddress actual;

    /* Initialize the source (expected) */
    addrString = [[TRString alloc] initWithCString: "127.0.0.1"];
    pfAddr = [[TRPFAddress alloc] initWithPresentationAddress: addrString];
    
    fail_if(pfAddr == nil);
    [pfAddr address: &expected];
    
    [addrString release];
    [pfAddr release];

    /* Initialize the dest (actual) */
    pfAddr = [[TRPFAddress alloc] initWithPortableAddress: &expected];
    fail_if(pfAddr == nil);
    [pfAddr address: &actual];
    [pfAddr release];

    /* Verify */
    fail_unless(memcmp(&actual, &expected, sizeof(expected)) == 0);
}
END_TEST


Suite *TRPFAddress_suite(void) {
    Suite *s = suite_create("TRPFAddress");

    TCase *tc_addr = tcase_create("Address");
    suite_add_tcase(s, tc_addr);
    tcase_add_test(tc_addr, test_initWithPresentationAddress);
    tcase_add_test(tc_addr, test_initWithPortableAddress);

    return s;
}
