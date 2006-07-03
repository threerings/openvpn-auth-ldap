/*
 * TRArray.m
 * Simple linked list with a non-thread-safe iterator
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

@implementation TRArray

- (id) init {
	self = [super init];
	if (!self)
		return self;

	/* Initialize our linked list */
	_stack = xmalloc(sizeof(TRArrayStack));
	_stack->object= nil;
	_stack->next = NULL;

	return self;
}

- (void) dealloc {
	TRArrayStack *node;

	/* Clean up our stack */
	for (node = _stack; node->next; node = node->next) {
		/* Release the associated object */
		[node->object release];
		free(node);
	}
	[super dealloc];
}

- (void) addObject: (id) anObject {
	TRArrayStack *node;

	/* Allocate, initialize, and push the new node on to the stack */
	node = xmalloc(sizeof(TRArrayStack));
	node->object = [anObject retain];
	node->next = _stack;

	_stack = node;
}

- (void) removeObject {
	TRArrayStack *node;

	/* Pop the stack */
	node = _stack;
	_stack = _stack->next;

	/* Dealloc the removed node */
	[node->object release];
	free(node);
}

- (id) lastObject {
	/* Return the last object on the stack */
	return _stack->object;
}

@end
