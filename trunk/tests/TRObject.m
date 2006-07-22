/*
 * TRObject.m
 * TRObject Unit Tests
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

#include <src/TRObject.h>

START_TEST (test_retainRelease) {
	TRObject *obj;

	/* Initialize the object */
	obj = [[TRObject alloc] init];
	fail_unless([obj refCount] == 1, "Newly initialized TRObject has unexpected reference count (Expected 1, got %d)", [obj refCount]);

	/* Increment the refcount */
	[obj retain];
	fail_unless([obj refCount] == 2, "Retained TRObject has unexpected reference count (Expected 2, got %d)", [obj refCount]);

	/* Decrement the refcount */
	[obj release];
	fail_unless([obj refCount] == 1, "Released TRObject has unexpected reference count (Expected 1, got %d)", [obj refCount]);

	/* Deallocate the object */
	[obj release];
}
END_TEST

START_TEST (test_isEqual) {
	TRObject *obj;

	/* Initialize the object */
	obj = [[TRObject alloc] init];

	fail_unless([obj isEqual: obj]);

	/* Deallocate the object */
	[obj release];
}
END_TEST


Suite *TRObject_suite(void) {
	Suite *s = suite_create("TRObject");

	TCase *tc_general = tcase_create("General");
	suite_add_tcase(s, tc_general);
	tcase_add_test(tc_general, test_isEqual);

	TCase *tc_refcount = tcase_create("Reference Counting");
	suite_add_tcase(s, tc_refcount);
	tcase_add_test(tc_refcount, test_retainRelease);


	return s;
}
