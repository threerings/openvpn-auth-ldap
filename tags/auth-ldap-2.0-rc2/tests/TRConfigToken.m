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
#define TEST_LINE_NUMBER 42

START_TEST (test_initWithBytes) {
	int tokenID;
	unsigned int lineNumber;
	TRConfigToken *token;

	token = [[TRConfigToken alloc] initWithBytes: TEST_STRING
					    numBytes: sizeof(TEST_STRING)
					  lineNumber: TEST_LINE_NUMBER
					     tokenID: TOKEN_VALUE];
	fail_if(token == NULL, "-[[TRConfigToken alloc] initWithBytes: numBytes: tokenID:] returned NULL");

	tokenID = [token tokenID];
	fail_unless(tokenID == TOKEN_VALUE, "-[TRConfigToken tokenID] returned incorrect value. (Expected %d, got %d)", tokenID, TOKEN_VALUE);

	lineNumber = [token lineNumber];
	fail_unless(lineNumber == TEST_LINE_NUMBER, "-[TRConfigToken lineNumber] returned incorrect value. (Expected %d, got %d)", TEST_LINE_NUMBER, lineNumber);

	[token release];
}
END_TEST

START_TEST (test_intValue) {
	TRConfigToken *token;
	int value;

	token = [[TRConfigToken alloc] initWithBytes: "24" 
					    numBytes: sizeof("24")
					  lineNumber: TEST_LINE_NUMBER
					     tokenID: TOKEN_VALUE];
	fail_if(token == NULL, "-[[TRConfigToken alloc] initWithBytes: numBytes: tokenID:] returned NULL");

	fail_unless([token intValue: &value], "-[TRConfigToken intValue:] returned NO");
	fail_unless(value == 24, "-[TRConfigToken value] returned incorrect value. (Expected %d, got %d)", 24, value);

	[token release];
}
END_TEST

START_TEST (test_boolValue) {
	TRConfigToken *token;
	BOOL value;

	token = [[TRConfigToken alloc] initWithBytes: "yes" 
					    numBytes: sizeof("yes")
					  lineNumber: TEST_LINE_NUMBER
					     tokenID: TOKEN_VALUE];

	fail_unless([token boolValue: &value], "-[TRConfigToken boolValue:] returned NO");

	fail_unless(value == YES, "-[TRConfigToken value] returned incorrect value. (Expected %d, got %d)", YES, value);

	[token release];

	token = [[TRConfigToken alloc] initWithBytes: "no" 
					    numBytes: sizeof("no")
					  lineNumber: TEST_LINE_NUMBER
					     tokenID: TOKEN_VALUE];

	fail_unless([token boolValue: &value], "-[TRConfigToken boolValue:] returned NO");

	fail_unless(value == NO, "-[TRConfigToken value] returned incorrect value. (Expected %d, got %d)", NO, value);

	[token release];
}
END_TEST


Suite *TRConfigToken_suite(void) {
	Suite *s = suite_create("TRConfigToken");

	TCase *tc_token = tcase_create("Token Operations");
	suite_add_tcase(s, tc_token);
	tcase_add_test(tc_token, test_initWithBytes);
	tcase_add_test(tc_token, test_intValue);
	tcase_add_test(tc_token, test_boolValue);

	return s;
}
