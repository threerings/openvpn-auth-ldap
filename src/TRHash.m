/*
 * TRHash.m
 * Hash Table
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

#include "TRHash.h"
#include <string.h>
#include <assert.h>

/*!
 * Hash key enumerator.
 */
@interface TRHashKeyEnumerator : TREnumerator <TREnumerator> {
	TRHash *_hash;
	hscan_t _scan;
	hash_t *_hashContext;
}

- (id) initWithHash: (TRHash *) hash;

@end

/*
 * We need to declare prototypes for our private methods, as some broken
 * versions of gcc won't pick them up from the implementation.
 */
@interface TRHash (TRHashPrivate)
- (hash_t *) _privateHashContext;
@end


@implementation TRHash

/*
 * Supporting functions
 */
static hash_val_t hash_function(const void *key) {
	return [(LFString *) key hash];
}

static int hash_key_compare(const void *firstValue, const void *secondValue) {
	return strcmp([(LFString *) firstValue cString], [(LFString *) secondValue cString]);
}

- (void) dealloc {
	hscan_t scan;
	hnode_t *node;

	/* Release every member of the hash */
	hash_scan_begin(&scan, _hash);
	while ((node = hash_scan_next(&scan)) != NULL) {
		/* Remove the node from the hash table */
		hash_scan_delete(_hash, node);

		/* Release the data */
		id obj;
		obj = (id) hnode_get(node);
		[obj release];

		/* Release the key */
		obj = (id) hnode_getkey(node);
		[obj release];

		/* Destroy the node */
		hnode_destroy(node);
	}

	/* Deallocate the hash table */
	hash_destroy(_hash);

	/* Pass control on to our superclass */
	[super dealloc];
}

/*!
 * Initialize a new TRHash with an maximum capacity of
 * numItems.
 */
- (id) initWithCapacity: (unsigned long) numItems {
	self = [self init];
	if (!self)
		return nil;

	/* Initialize our hash table */
	_hash = hash_create(numItems, &hash_key_compare, &hash_function);

	return self;
}

/*!
 * Remove the key and associated value from the hash table.
 */
- (void) removeObjectForKey: (LFString *) key {
	hnode_t *node;
	id obj;

	/* Look for an existing key */
	node = hash_lookup(_hash, key);
	if (!node)
		return;

	/* Remove the node */
	tr_hash_delete(_hash, node);

	/* Drop the old value */
	obj = (id) hnode_get(node);
	[obj release];

	/* Drop the old key */
	obj = (id) hnode_getkey(node);
	[obj release];

	/* Destroy the node */
	hnode_destroy(node);
}

/*!
 * Returns the associated value for a given key.
 */
- (id) valueForKey: (LFString *) key {
	hnode_t *node;

	/* Look up the key */
	node = hash_lookup(_hash, key);
	if (!node)
		return nil;

	/* Return associated value */
	return (id) hnode_get(node);
}


/*!
 * Add anObject to the hash table with key.
 * Both the key and value are retained.
 */
- (void) setObject: (id) anObject forKey: (LFString *) key {
	hnode_t *node;

	/* Remove the key, if it exists */
	[self removeObjectForKey: key];

	/* Are we at capacity? Programmer error! */
	assert(hash_isfull(_hash) == 0);

	/* Retain our key and value */
	[anObject retain];
	[key retain];

	/* Insert them into the hash table */
	node = hnode_create(anObject);
	hash_insert(_hash, node, key);
}

- (hash_t *) _privateHashContext {
	return _hash;
}

/*!
 * Return a key enumerator.
 * Due to our lack of an autorelease pool,
 * it is the caller's responsibility to release
 * the returned value.
 */
- (TREnumerator *) keyEnumerator {
	return [[TRHashKeyEnumerator alloc] initWithHash: self];
}

@end /* TRHash */

@implementation TRHashKeyEnumerator

- (void) dealloc {
	[_hash release];
	[super dealloc];
}

- (id) initWithHash: (TRHash *) hash {
	self = [super init];
	if (!self)
		return self;

	_hash = [hash retain];
	_hashContext = [hash _privateHashContext];
	hash_scan_begin(&_scan, _hashContext);

	return self;
}

- (id) nextObject {
	hnode_t *node;

	node = hash_scan_next(&_scan);
	if (!node)
		return nil;

	return (id) hnode_getkey(node);
}

@end /* TRHashKeyEnumerator */


