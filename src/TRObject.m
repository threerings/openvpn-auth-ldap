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
#import "TRAutoreleasePool.h"

#import <objc/runtime.h>

@interface Object (QuiesceWarnings)

// WARNING: Depending on the libobjc implementation, neither of these may
// be implemented.
- (id) init;
- (void) dealloc;

@end

/**
 * Base class. Handles reference counting and equality.
 */
@implementation TRObject

/**
 * Allocate a new instance of the receiver.
 */
+ (id) alloc {
    return class_createInstance(self, 0);
}

/**
 * Implemented by subclasses to initialize a newly allocated object. The default
 * implementation performs no initialization.
 */
- (id) init {
    // self = [super init];
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
    object_dispose(self);

    /* Quiesce compiler warnings regarding missing call to -dealloc */
    if (false)
        [super dealloc];
}

// from TRObject protocol
- (Class) class {
    return object_getClass(self);
}

// from TRObject protocol
- (BOOL) isEqual: (id) anObject {
    if (self == anObject)
        return YES;
    else
        return NO;
}

// from TRObject protocol
- (BOOL) isKindOfClass: (Class) cls {
    Class selfClass = [self class];

    /* Determine if this is a subclass of PXTestCase. By starting with the class
     * itself, we skip over the non-subclassed PLInstrumentCase class. */
    for (Class superClass = selfClass; superClass != NULL; superClass = class_getSuperclass(superClass)) {
        if (superClass == cls)
            return YES;
    }

    return NO;
}

// from TRObject protocol
- (PXUInteger) retainCount {
    return _refCount;
}

// from TRObject protocol
- (id) retain {
    _refCount++;
    return self;
}

// from TRObject protocol
- (oneway void) release {
    /* This must never occur */
    assert(_refCount >= 1);

    /* Decrement refcount, if zero, dealloc */
    _refCount--;
    if (!_refCount)
        [self dealloc];
}

// from TRObject protocol
- (id) autorelease {
        [TRAutoreleasePool addObject: self];
        return self;
}

/* Don't auto-release the class object! */
+ (id) autorelease {
        return self;
}

@end
