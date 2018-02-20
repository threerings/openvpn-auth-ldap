/*
 * TRString.m vi:ts=4:sw=4:expandtab:
 * TRString Unit Tests
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
 * 3. Neither the name of Landon Fuller nor the names of any contributors
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

#import "PXTestCase.h"

#import "TRString.h"

#include <Foundation/NSAutoreleasePool.h>

#import <string.h>
#import <limits.h>

#define TEST_STRING "Hello, World!"

@interface TRStringTests: PXTestCase @end

@implementation TRStringTests

- (void) test_initWithCString {
    const char *cString = TEST_STRING;
    TRString *str;

    str = [[TRString alloc] initWithCString: cString];
    fail_if(str == NULL, "-[[TRString alloc] initWithCString:] returned NULL");
    cString = [str cString];
    fail_unless(strcmp(cString, TEST_STRING) == 0, "-[TRString cString] returned incorrect value. (Expected \"%s\", got \"%s\")", TEST_STRING, cString);
    [str release];
}


- (void) test_initWithString {
    const char *cString = TEST_STRING;
    TRString *srcString = [[TRString alloc] initWithCString: cString];
    TRString *str;

    str = [[TRString alloc] initWithString: srcString];
    fail_if(str == NULL, "-[[TRString alloc] initWithString:] returned NULL");
    cString = [str cString];
    fail_unless(strcmp(cString, TEST_STRING) == 0, "-[TRString cString] returned incorrect value. (Expected \"%s\", got \"%s\")", TEST_STRING, cString);

    [srcString release];
    [str release];
}


- (void) test_initWithBytes {
    const char *data = TEST_STRING;
    const char *cString;
    TRString *str;

    /* Test with non-NULL terminated data */
    str = [[TRString alloc] initWithBytes: data numBytes: sizeof(TEST_STRING) - 1];
    fail_if(str == NULL, "-[[TRString alloc] initWithBytes:] returned NULL");
    cString = [str cString];
    fail_unless(strcmp(cString, TEST_STRING) == 0, "-[TRString cString] returned incorrect value. (Expected \"%s\", got \"%s\")", TEST_STRING, cString);

    [str release];

    /* Test with NULL terminated data */
    str = [[TRString alloc] initWithBytes: data numBytes: sizeof(TEST_STRING)];
    fail_if(str == NULL, "-[[TRString alloc] initWithBytes:] returned NULL");
    cString = [str cString];
    fail_unless(strcmp(cString, TEST_STRING) == 0, "-[TRString cString] returned incorrect value. (Expected \"%s\", got \"%s\")", TEST_STRING, cString);

    [str release];
}


- (void) test_stringWithFormat {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    TRString *str;
    
    str = [TRString stringWithFormat: "%s %s", "Hello", "World"];
    fail_unless(strcmp([str cString], "Hello World") == 0,
        "-[TRString cString] returned incorrect value. (Expected \"%s\", got \"%s\")", "Hello, World", [str cString]);

    [pool drain];
}


- (void) test_stringWithCString {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    TRString *str;
    
    str = [TRString stringWithCString: "Hello World"];
    fail_unless(strcmp([str cString], "Hello World") == 0,
        "-[TRString cString] returned incorrect value. (Expected \"%s\", got \"%s\")", "Hello, World", [str cString]);

    [pool drain];
}


- (void) test_length {
    TRString *str = [[TRString alloc] initWithCString: TEST_STRING];
    size_t length = [str length];

    fail_unless(length == sizeof(TEST_STRING), "-[TRString length] returned incorrect value. (Expected %u, got %u)", sizeof(TEST_STRING), length);
    [str release];
}


- (void) test_intValue {
    TRString *str;
    int i;
    bool success;

    /* Test with integer */
    str = [[TRString alloc] initWithCString: "20"];
    success = [str intValue: &i];
    fail_unless(success, "-[TRString intValue:] returned false");
    fail_unless(i == 20, "-[TRString intValue:] returned incorrect value. (Expected %d, got %d)", 20, i);
    [str release];

    /* Test with INT_MAX */
    str = [[TRString alloc] initWithCString: "2147483647"];
    success = [str intValue: &i];
    fail_if(success, "-[LFstring intValue:] returned true for INT_MAX.");
    fail_unless(i == INT_MAX, "-[TRString intValue: returned incorrect value for INT_MAX. (Expected %d, got %d)", INT_MAX, i);
    [str release];

    /* Test with INT_MIN */
    str = [[TRString alloc] initWithCString: "-2147483648"];
    success = [str intValue: &i];
    fail_if(success, "-[LFstring intValue:] returned true for INT_MIN.");
    fail_unless(i == INT_MIN, "-[TRString intValue: returned incorrect value for INT_MIN. (Expected %d, got %d)", INT_MIN, i);
    [str release];
}


- (void) test_hash {
    TRString *str = [[TRString alloc] initWithCString: TEST_STRING];
    PXUInteger hash = [str hash];

    fail_if(hash == 0);
    [str release];
}


@end
