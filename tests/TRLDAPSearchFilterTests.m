/*
 * TRLDAPSearchFilter.m vi:ts=4:sw=4:expandtab:
 * TRLDAPSearchFilter Unit Tests
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

#import <string.h>

#import "TRLDAPSearchFilter.h"

@interface TRLDAPSearchFilterTests : PXTestCase @end

@implementation TRLDAPSearchFilterTests

- (void) test_initWithFormat {
    TRLDAPSearchFilter *filter = [[TRLDAPSearchFilter alloc] initWithFormat: [TRString stringWithCString: "%s foo"]];

    [filter release];
}

- (void) test_getFilter {
    TRLDAPSearchFilter *filter = [[TRLDAPSearchFilter alloc] initWithFormat: [TRString stringWithCString: "(&(uid=%s)(cn=%s))"]];
    const char *expected = "(&(uid=fred)(cn=fred))";
    TRString *result = [filter getFilter: [TRString stringWithCString: "fred"]];

    fail_unless(strcmp([result cString], expected) == 0,
        "-[TRLDAPSearchFilter createFilter:] returned incorrect string. (Expected %s, got %s)", expected, [result cString]);

    [filter release];
}

- (void) test_ldapEscaping {
    TRLDAPSearchFilter *filter = [[TRLDAPSearchFilter alloc] initWithFormat: [TRString stringWithCString: "(%s)"]];
    const char *expected = "(\\(foo\\*\\)\\\\)";
    
    /* Pass in something containing all the special characters */
    TRString *result = [filter getFilter: [TRString stringWithCString: "(foo*)\\"]];

    fail_unless(strcmp([result cString], expected) == 0,
        "-[TRLDAPSearchFilter createFilter:] returned incorrect string. (Expected %s, got %s)", expected, [result cString]);

    [filter release];
}

@end