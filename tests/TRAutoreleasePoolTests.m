/*
 * TRAutoreleasePool.m vi:ts=4:sw=4:expandtab:
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

#import "TRAutoreleasePool.h"
#import "PXTestCase.h"

static unsigned int livecount;

@interface PoolTester : TRObject
@end

@implementation PoolTester

- (oneway void) release {
    livecount--;
    [super release];
}

- (void) dealloc {
    livecount--;
    [super dealloc];
}

@end

@interface TRAutoreleasePoolTests : PXTestCase @end

@implementation TRAutoreleasePoolTests

- (void) testAddObject {
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

@end
