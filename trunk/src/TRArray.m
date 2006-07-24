/*
 * TRArray.m
 * Simple linked list
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

#include <stdlib.h>

#include "TRArray.h"
#include "auth-ldap.h"

typedef struct _TRArrayStack {
	id object;
	struct _TRArrayStack *next;
} TRArrayStack;

/*!
 * Linked list enumerator
 */
@interface TRArrayObjectEnumerator : TREnumerator {
	TRArray *_array;
	TRArrayStack *_stack;
}
- (id) initWithArray: (TRArray *) array;
@end


@implementation TRArray

- (id) init {
	self = [super init];
	if (!self)
		return self;

	_count = 0;

	/* Initialize our linked list */
	_stack = xmalloc(sizeof(TRArrayStack));
	_stack->object= nil;
	_stack->next = NULL;

	return self;
}

- (void) dealloc {
	TRArrayStack *node;

	/* Clean up our stack */
	for (node = _stack; _stack; node = _stack) {
		/* Release the associated object */
		[node->object release];
		_stack = node->next;
		free(node);
	}
	[super dealloc];
}

- (unsigned int) count {
	return _count;
}

/*!
 * Add anObject to the array.
 * @param anObject: Object to add;
 */
- (void) addObject: (id) anObject {
	TRArrayStack *node;

	/* Allocate, initialize, and push the new node on to the stack */
	node = xmalloc(sizeof(TRArrayStack));
	node->object = [anObject retain];
	node->next = _stack;

	_stack = node;
	_count++;
}

/*!
 * Remove top-most object from the array (LIFO).
 */
- (void) removeObject {
	TRArrayStack *node;

	/* Pop the stack */
	node = _stack;
	_stack = _stack->next;

	/* Dealloc the removed node */
	[node->object release];
	free(node);
	_count--;
}

/*!
 * Return the last object added to the array.
 * @return Last object added to the array.
 */
- (id) lastObject {
	/* Return the last object on the stack */
	return _stack->object;
}

/*!
 * Test if the array contains anObject.
 * Implemented by calling isEqual on all objects in the array.
 * @param anObject: Object to test for equality.
 * @return YES if the array contains anObject, NO otherwise.
 */
- (BOOL) containsObject: (id) anObject {
	TRArrayStack *node;

	/* Anything claim to be equal with anObject? */
	for (node = _stack; node; node = node->next) {
		if ([node->object isEqual: anObject])
			return YES;
	}

	return NO;
}

- (TRArrayStack *) _privateArrayContext {
        return _stack;
}

/*!
 * Return a object enumerator.
 * Due to our lack of an autorelease pool,
 * it is the caller's responsibility to release
 * the returned value.
 */
- (TREnumerator *) objectEnumerator {
        return [[TRArrayObjectEnumerator alloc] initWithArray: self];
}

@end /* TRArray */

@implementation TRArrayObjectEnumerator

- (void) dealloc {
        [_array release];
        [super dealloc];
}

- (id) initWithArray: (TRArray *) array {
        self = [super init];
        if (!self)
                return self;

        _array = [array retain];
        _stack = [array _privateArrayContext];

        return self;
}

- (id) nextObject {
	TRArrayStack *next;

	if (!_stack)
		return nil;

	/* Pop the next node from the stack */
	next = _stack;
	_stack = _stack->next;

	/* Return the next node */
	return (next->object);
}

@end /* TRArrayObjectEnumerator */
