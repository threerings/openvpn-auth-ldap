/*
 * TRObject.m vi:ts=4:sw=4:expandtab:
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

#import <assert.h>
#import <stdarg.h>

#import "TRObject.h"
#import "util/TRAutoreleasePool.h"

#import <objc/runtime.h>

#ifndef HAVE_FRAMEWORK_FOUNDATION 
@interface Object (QuiesceWarnings)
- (void) dealloc;
@end
#endif /* !HAVE_FRAMEWORK_FOUNDATION */

/**
 * Base class. Handles reference counting and equality.
 */
@implementation TRObject

#ifndef HAVE_FRAMEWORK_FOUNDATION

- (id) init {
    self = [super init];
    if (!self)
        return self;

    _refCount = 1;
    return self;
}

/**
 * Called upon deallocation of the receiver. Responsible for discarding all resources held by the
 * receiver.
 *
 * This method will be called automatically when the receiver's reference count reaches 0. It should
 * never be called directly. As an exception to this, subclass implementations of -dealloc must
 * incorporate the superclass implementation through a message to super.
 */
- (void) dealloc {
    [super free];

    /* Quiesce compiler warnings regarding missing call to -dealloc */
    if (false)
        [super dealloc];
}

/**
 * Return YES if the receiver is equal to @a anObject.
 *
 * The default implementation of this method performs a check for pointer equality. Subclasses may override this
 * method to check for value equality.
 *
 * @note If two objects are equal, they must also have the same hash value.
 */ 
- (BOOL) isEqual: (id) anObject {
    if (self == anObject)
        return YES;
    else
        return NO;
}

/**
 * Returns YES if the receiver is an instance of the given @a cls, or any class that inherits
 * from cls.
 *
 * @param cls The class against which the receiver's class will be tested.
 */
- (BOOL) isKindOfClass: (Class) cls {
    Class selfClass = [self class];

    /* Determine if this is a subclass of PXTestCase. By starting with the class
     * itself, we skip over the non-subclassed PLInstrumentCase class. */
    for (Class superClass = cls; superClass != NULL; superClass = class_getSuperclass(superClass)) {
        if (superClass == selfClass)
            return YES;
    }

    return NO;
}

/**
 * Return the current object retain count. This does not take into account any enqueued autorelease calls,
 * and should generally not be used.
 */
- (unsigned int) retainCount {
    return _refCount;
}

/**
 * Retain a reference to the receiver, incrementing the reference count.
 */
- (id) retain {
    _refCount++;
    return self;
}

/**
 * Release a reference to the receiver, decrementing the reference count. If the reference count reaches zero,
 * the receiver will be deallocated.
 */
- (void) release {
    /* This must never occur */
    assert(_refCount >= 1);

    /* Decrement refcount, if zero, dealloc */
    _refCount--;
    if (!_refCount)
        [self dealloc];
}

/*!
 * Add the object to the current autorelease pool. Objects in the autorelease
 * pool will be released at a later time.
 * @result Returns a reference to the receiver.
 */
- (id) autorelease {
        [TRAutoreleasePool addObject: self];
        return self;
}

/* Don't auto-release the class object! */
+ (id) autorelease {
        return self;
}

#endif /* HAVE_FRAMEWORK_FOUNDATION */

@end
