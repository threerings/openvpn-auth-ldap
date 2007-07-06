/* 
 * TRAutoreleasePool.m vi:ts=4:sw=4:expandtab:
 *
 * Copyright (C) 2006 - 2007 Landon Fuller <landonf@opendarwin.org>
 * All rights reserved.
 *
 * Author: Landon Fuller <landonf@opendarwin.org
 *
 * This file is part of Substrate.
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


/*!
 * @file
 * @brief TRAutoreleasePool
 */

/*!
 * @defgroup TRAutoreleasePool TRAutoreleasePool
 * @{
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <stdlib.h>
#include <pthread.h>
#include <assert.h>

#include "TRAutoreleasePool.h"
#include "xmalloc.h"

/* Number of objects to store in each pool bucket.
 * Selected arbitrarily. */
#define BUCKET_SIZE 1024

/*
 * Each thread maintains a stack
 * of TRAutoreleasePools.
 */
typedef struct _TRAutoreleasePoolStack {
    TRAutoreleasePool *pool;
    struct _TRAutoreleasePoolStack *next;
} TRAutoreleasePoolStack;

/*
 * TRAutoreleasePools store autoreleased
 * objects in a linked list of buckets.
 */
struct _TRAutoreleasePoolBucket {
    int count;
    id objects[BUCKET_SIZE];
    struct _TRAutoreleasePoolBucket *next;
};


#ifdef HAVE_THREADLS
static __thread TRAutoreleasePoolStack *autorelease_stack;
# define CURTHREAD_GET_POOLSTACK()    autorelease_stack
# define CURTHREAD_SET_POOLSTACK(x)    autorelease_stack = x
#else
static pthread_key_t autorelease_stack_key;
# define CURTHREAD_GET_POOLSTACK()    (TRAutoreleasePoolStack *) pthread_getspecific(autorelease_stack_key)
# define CURTHREAD_SET_POOLSTACK(x)    pthread_setspecific(autorelease_stack_key, (void *) x)
#endif /* HAVE_THEADLS */

/*
 * Allocate and initialize a new bucket, attach it to the
 * supplied bucket.
 */
static TRAutoreleasePoolBucket *bucket_add (TRAutoreleasePoolBucket *bucket) {
    TRAutoreleasePoolBucket *new;

    /* Allocate and initialize the bucket */
    new = xmalloc(sizeof(TRAutoreleasePoolBucket));
    new->count = 0;
    new->next = bucket;

    return new;
}

/*
 * Free the bucket stack, sending release messages to the contained objects.
 */
static void bucket_flush (TRAutoreleasePoolBucket *bucket) {
    TRAutoreleasePoolBucket *next, *cur;
    int i;

    /* Free all buckets */
    cur = bucket;
    while (cur != NULL) {
        /* Send release message to all objects in the bucket */
        for (i = 0; i < cur->count; i++) {
            [cur->objects[i] release];
        }
        next = cur->next;
        free(cur);
        cur = next;
    }
}

/*!
 * @brief Foundation Allocation Pool Class.
 *
 * TRAutoreleasePool provides an API for implementing per-thread pools of
 * autoreleased objects. When an object is sent the autorelease method,
 * it is added to the current thread's autorelease pool. Per-thread
 * pools are implemented using a stack -- when a new pool is allocated,
 * it is pushed onto the stack, and all new autoreleased objects are
 * placed in that pool.
 * 
 * When the autorelease pool is deallocated, all autoreleased objects
 * are sent release messages. You may add an object to an autorelease
 * pool multiple times, and it will be sent multiple release messages.
 *
 * You must deallocate autorelease pools in the same order they were
 * allocated.
 */
@implementation TRAutoreleasePool

#ifndef HAVE_THREADLS
+ initialize {
    if (self == [TRAutoreleasePool class]) {
        /* Initialize our pthread key */
        pthread_key_create(&autorelease_stack_key, NULL);
    }
    return self;
}
#endif

- (id) init {
    TRAutoreleasePoolStack *stack, *threadStack;
    
    if ((self = [super init]) == nil) {
        return self;
    }

    /* Grab the thread-specific pool stack pointer */
    threadStack = CURTHREAD_GET_POOLSTACK();

    /* Allocate our new stack */
    stack = xmalloc(sizeof(TRAutoreleasePoolStack));
    stack->pool = self;

    /* If a current stack exists, append the new one,
     * otherwise, we're the first stack */
    if (threadStack != NULL)
        /* We are a sub-pool */
        stack->next = threadStack;
    else
        /* We are the first pool */
        stack->next = NULL;

        /* Set new per-thread pool stack */
    CURTHREAD_SET_POOLSTACK(stack);

    /* Allocate and initialize our bucket */
    poolBucket = xmalloc(sizeof(TRAutoreleasePoolBucket));
    poolBucket->count = 0;
    poolBucket->next = NULL;

    return self;
}

- (void) dealloc {
    TRAutoreleasePoolStack *stack;

    /* Free our buckets */
    bucket_flush(poolBucket);

    /* Pop our pool stack */
    stack = CURTHREAD_GET_POOLSTACK();
    CURTHREAD_SET_POOLSTACK(stack->next);
    free(stack);

    [super dealloc];
}

/*!
 * Add anObject to the current thread's
 * active autorelease pool.
 */
+ (void) addObject:(id)anObject {
    TRAutoreleasePoolStack *stack;

    /* Get our per-thread stack */
    stack = CURTHREAD_GET_POOLSTACK();
    assert(stack != NULL);

    [stack->pool addObject: anObject];
}

/*!
 * Add anObject to the receiver.
 */
- (void) addObject:(id)anObject {
    /* If the current bucket is full, create a new one */    
    if (poolBucket->count == BUCKET_SIZE) {
        poolBucket = bucket_add(poolBucket);
    }

    poolBucket->objects[poolBucket->count] = anObject;
    poolBucket->count++;
}

- (id) retain {
    /* Can not retain an autorelease pool. */
    abort();
    
    /* Not reached. */
    return nil;
}

- (id) autorelease {
    /* Can not autorelease an autorelease pool. */
    abort();

    /* Not reached */
    return nil;
}

@end

/*! @} */
