/*
 * TRAutoreleasePool.m
 *
 * Copyright (C) 2005 - 2007 Landon Fuller <landonf@opendarwin.org>
 * All rights reserved.
 *
 * This file is part of Objective-C Substrate.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose and without fee is hereby granted, provided
 * that the above copyright notice appear in all copies and that both that
 * copyright notice and this permission notice appear in supporting
 * documentation.
 *
 * We disclaim all warranties with regard to this software, including all
 * implied warranties of merchantability and fitness, in no event shall
 * we be liable for any special, indirect or consequential damages or any
 * damages whatsoever resulting from loss of use, data or profits, whether in
 * an action of contract, negligence or other tortious action, arising out of
 * or in connection with the use or performance of this software.
 */

#include <check.h>

#include <util/TRAutoreleasePool.h>

static unsigned int livecount;

@interface PoolTester : TRObject
@end

@implementation PoolTester

- (void) release {
	livecount--;
	[super release];
}

- (void) dealloc {
	livecount--;
	[super dealloc];
}

@end

START_TEST (test_TRAutoreleasePool_addObject) {
	TRAutoreleasePool *pool;
	TRObject *obj;
	int i;

	/* Allocate a pool */
	pool = [[TRAutoreleasePool alloc] init];
	fail_if(pool == nil, "[[TRAutoreleasePool alloc] init] returned nil.\n");

	/* Allocate an object to auto-release */
	obj = [[PoolTester alloc] init];
	[obj autorelease];

	/* Implicit refcount + dealloc */
	livecount = 2;

	/* Exercise the pool */
	for (i = 0; i < 4096; i++) {
		livecount++;
		[obj retain];
		[obj autorelease];
	}

	/* Release it */
	[pool release];

	fail_unless(livecount == 0, "[TRAutoreleasePool release] failed to release %d objects.", livecount);
}
END_TEST

Suite *TRAutoreleasePool_suite(void) {
	Suite *s = suite_create("TRAutoreleasePool");

	TCase *tc = tcase_create("Default");

	suite_add_tcase(s, tc);

	tcase_add_test(tc, test_TRAutoreleasePool_addObject);

	return s;
}
