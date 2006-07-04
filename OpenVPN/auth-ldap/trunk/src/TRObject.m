/*
 * TRObject.m
 * Project Root Class
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

#include <assert.h>

#include "TRObject.h"

/*
 * Apple's Obj-C compiler assumes that all objects
 * inherit from NSObject, and must call [super dealloc]
 * in their dealloc method. If you don't, the compiler
 * complains.
 *
 * So, let's pretend to give Object a dealloc method,
 * but never call it.
 * Thanks Apple!
 *
 * Additionally, we implement brain-dead, non-thread-safe
 * reference counting.
 */ 
@interface Object (AppleAddedAReallyStupidGCCWarning)
- (void) dealloc;
@end

@implementation TRObject

- (id) init {
	self = [super init];
	if (!self)
		return self;

	_refCount = 1;
	return self;
}

- (void) dealloc {
	[super free];

	/* Make Apple's objc compiler be quiet */
	if (false)
		[super dealloc];
}

- (unsigned int) refCount {
	return _refCount;
}

- (id) retain {
	_refCount++;
	return self;
}

- (BOOL) isEqual: (id) anObject {
	if (self == anObject)
		return YES;
	else
		return NO;
}

- (void) release {
	/* This must never occur */
	assert(_refCount >= 1);

	/* Decrement refcount, if zero, dealloc */
	_refCount--;
	if (!_refCount)
		[self dealloc];
}

@end
