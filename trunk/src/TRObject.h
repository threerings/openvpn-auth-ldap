/*
 * TRObject.h vi:ts=4:sw=4:expandtab:
 * Project Root Class
 *
 * Author: Landon Fuller <landonf@threerings.net>
 *
 * Copyright (c) 2007 Landon Fuller <landonf@threerings.net>
 * Copyright (c) 2006 - 2007 Three Rings Design, Inc.
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
#import <config.h>
#endif

#import <stdbool.h>

#import "PXObjCRuntime.h"

#ifdef HAVE_FRAMEWORK_FOUNDATION
#import <Foundation/Foundation.h>

@protocol TRObject <NSObject>
@end

@interface TRObject : NSObject <TRObject>
@end

#else /* HAVE_FRAMEWORK_FOUNDATION */

#import <objc/Object.h>

@protocol TRObject

/**
 * Return the current object retain count. This does not take into account any enqueued autorelease calls,
 * and should generally not be used.
 */
- (unsigned int) retainCount;

/**
 * Retain a reference to the receiver, incrementing the reference count.
 */
- (id) retain;

/**
 * Release a reference to the receiver, decrementing the reference count. If the reference count reaches zero,
 * the receiver will be deallocated.
 */
- (oneway void) release;

/**
 * Add the object to the current autorelease pool. Objects in the autorelease
 * pool will be released at a later time.
 * @result Returns a reference to the receiver.
 */
- (id) autorelease;

/**
 * Return the receiver's class.
 */
- (Class) class;

/**
 * Return YES if the receiver is equal to @a anObject.
 *
 * The default implementation of this method performs a check for pointer equality. Subclasses may override this
 * method to check for value equality.
 *
 * @note If two objects are equal, they must also have the same hash value.
 */ 
- (BOOL) isEqual: (id) anObject;

/**
 * Returns YES if the receiver is an instance of the given @a cls, or any class that inherits
 * from cls.
 *
 * @param cls The class against which the receiver's class will be tested.
 */
- (BOOL) isKindOfClass: (Class) cls;

@end


@interface TRObject : Object <TRObject> {
@private
    unsigned int _refCount;
}

+ (id) alloc;

- (unsigned int) retainCount;
- (void) dealloc;

@end

#endif /* !HAVE_FRAMEWORK_FOUNDATION */
