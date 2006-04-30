/*
 * TRConfigToken.m
 * TRConfigToken Unit Tests
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
 * 3. Neither the name of the copyright holder nor the names of any contributors
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

#include <src/TRConfigToken.h>
#include <src/TRConfigParser.h>

#include <check.h>
#include <string.h>

#define TEST_STRING "The answer to life, the universe, and everything"

START_TEST (test_initWithBytes_ID) {
	int tokenID;
	TRConfigToken *token;

	token = [[TRConfigToken alloc] initWithBytes: TEST_STRING numBytes: sizeof(TEST_STRING) tokenID: VALUE];
	fail_if(token == NULL, "-[[TRConfigToken alloc] initWithBytes: numBytes: tokenID:] returned NULL");

	tokenID = [token getTokenID];
	fail_unless(tokenID == VALUE, "-[TRConfigToken getTokenID] returned incorrect value. (Expected %d, got %d)", tokenID, VALUE);

	[token dealloc];
}
END_TEST

Suite *TRConfigToken_suite(void) {
	Suite *s = suite_create("TRConfigToken");

	TCase *tc_token = tcase_create("Token Operations");
	suite_add_tcase(s, tc_token);
	tcase_add_test(tc_token, test_initWithBytes_ID);

	return s;
}
