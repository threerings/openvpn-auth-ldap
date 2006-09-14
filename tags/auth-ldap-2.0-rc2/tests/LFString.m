/*
 * LFString.m
 * LFString Unit Tests
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

#include <src/LFString.h>

#include <check.h>
#include <string.h>
#include <limits.h>

#define TEST_STRING "Hello, World!"

START_TEST (test_initWithCString) {
	const char *cString = TEST_STRING;
	LFString *str;

	str = [[LFString alloc] initWithCString: cString];
	fail_if(str == NULL, "-[[LFString alloc] initWithCString:] returned NULL");
	cString = [str cString];
	fail_unless(strcmp(cString, TEST_STRING) == 0, "-[LFString cString] returned incorrect value. (Expected \"%s\", got \"%s\")", TEST_STRING, cString);
	[str release];
}
END_TEST

START_TEST (test_initWithString) {
	const char *cString = TEST_STRING;
	LFString *srcString = [[LFString alloc] initWithCString: cString];
	LFString *str;

	str = [[LFString alloc] initWithString: srcString];
	fail_if(str == NULL, "-[[LFString alloc] initWithString:] returned NULL");
	cString = [str cString];
	fail_unless(strcmp(cString, TEST_STRING) == 0, "-[LFString cString] returned incorrect value. (Expected \"%s\", got \"%s\")", TEST_STRING, cString);

	[srcString release];
	[str release];
}
END_TEST

START_TEST (test_initWithBytes) {
	const char *data = TEST_STRING;
	const char *cString;
	LFString *str;

	/* Test with non-NULL terminated data */
	str = [[LFString alloc] initWithBytes: data numBytes: sizeof(TEST_STRING) - 1];
	fail_if(str == NULL, "-[[LFString alloc] initWithBytes:] returned NULL");
	cString = [str cString];
	fail_unless(strcmp(cString, TEST_STRING) == 0, "-[LFString cString] returned incorrect value. (Expected \"%s\", got \"%s\")", TEST_STRING, cString);

	[str release];

	/* Test with NULL terminated data */
	str = [[LFString alloc] initWithBytes: data numBytes: sizeof(TEST_STRING)];
	fail_if(str == NULL, "-[[LFString alloc] initWithBytes:] returned NULL");
	cString = [str cString];
	fail_unless(strcmp(cString, TEST_STRING) == 0, "-[LFString cString] returned incorrect value. (Expected \"%s\", got \"%s\")", TEST_STRING, cString);

	[str release];
}
END_TEST

START_TEST (test_length) {
	LFString *str = [[LFString alloc] initWithCString: TEST_STRING];
	size_t length = [str length];

	fail_unless(length == sizeof(TEST_STRING), "-[LFString length] returned incorrect value. (Expected %u, got %u)", sizeof(TEST_STRING), length);
	[str release];
}
END_TEST

START_TEST (test_intValue) {
	LFString *str;
	int i;
	bool success;

	/* Test with integer */
	str = [[LFString alloc] initWithCString: "20"];
	success = [str intValue: &i];
	fail_unless(success, "-[LFString intValue:] returned false");
	fail_unless(i == 20, "-[LFString intValue:] returned incorrect value. (Expected %d, got %d)", 20, i);
	[str release];

	/* Test with INT_MAX */
	str = [[LFString alloc] initWithCString: "2147483647"];
	success = [str intValue: &i];
	fail_if(success, "-[LFstring intValue:] returned true for INT_MAX.");
	fail_unless(i == INT_MAX, "-[LFString intValue: returned incorrect value for INT_MAX. (Expected %d, got %d)", INT_MAX, i);
	[str release];

	/* Test with INT_MIN */
	str = [[LFString alloc] initWithCString: "-2147483648"];
	success = [str intValue: &i];
	fail_if(success, "-[LFstring intValue:] returned true for INT_MIN.");
	fail_unless(i == INT_MIN, "-[LFString intValue: returned incorrect value for INT_MIN. (Expected %d, got %d)", INT_MIN, i);
	[str release];
}
END_TEST

START_TEST (test_hash) {
	LFString *str = [[LFString alloc] initWithCString: TEST_STRING];
	int hash = [str hash];

	fail_if(hash == 0);
	[str release];
}
END_TEST


Suite *LFString_suite(void) {
	Suite *s = suite_create("LFString");

	TCase *tc_string = tcase_create("String Handling");
	suite_add_tcase(s, tc_string);
	tcase_add_test(tc_string, test_initWithCString);
	tcase_add_test(tc_string, test_initWithString);
	tcase_add_test(tc_string, test_initWithBytes);
	tcase_add_test(tc_string, test_length);
	tcase_add_test(tc_string, test_intValue);
	tcase_add_test(tc_string, test_hash);

	return s;
}
