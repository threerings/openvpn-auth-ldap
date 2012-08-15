/*
 * TRLDAPSearchFilter.m vi:ts=4:sw=4:expandtab:
 * LDAP Search Filter Generator
 *
 * Author: Landon Fuller <landonf@threerings.net>
 *
 * Copyright (c) 2005 - 2008 Landon Fuller <landonf@threerings.net>
 * Copyright (c) 2007 - 2008 Three Rings Design, Inc.
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

#import "TRLDAPSearchFilter.h"
#import "TRAutoreleasePool.h"

@interface TRLDAPSearchFilter (TRLDAPSearchFilterPrivate)
 - (TRString *) escapeForSearch: (TRString *) string;
@end

@implementation TRLDAPSearchFilter

/**
 * Initialize with the given format string.
 * The only valid format specifier is %s -- it will be replaced with the
 * provided substitute string when -[TRLDAPSearchFilter getFilter] is called.
 */
- (id) initWithFormat: (TRString *) format {
    self = [super init];
    if (self == nil)
        return nil;

    _format = [format retain];

    return self;
}

- (void) dealloc {
    /* Release our format string */
    [_format release];

    /* Deallocate superclass */
    [super dealloc];
}

/**
 * Escape the provided string according to RFC 2254, escaping
 * any special LDAP search characters.
 */
- (TRString *) escapeForSearch: (TRString *) string {
    const char specialChars[] = "*()\\"; /* RFC 2254. We don't care about NULL */
    TRString *result = [[TRString alloc] init];
    TRString *unquotedString, *part;
    TRAutoreleasePool *pool = [[TRAutoreleasePool alloc] init];

    /* Retain an instance of the string */
    unquotedString = [string retain];

    /* Initialize the result */
    result = [[TRString alloc] init];

    /* Quote all occurrences of the special characters */
    while ((part = [unquotedString substringToCharset: specialChars]) != NULL) {
        TRString *temp;
        size_t index;
        char c;

        /* Append everything until the first special character */
        [result appendString: part];

        /* Append the backquote */
        [result appendCString: "\\"];

        /* Get the special character */
        index = [unquotedString indexToCharset: specialChars];
        temp = [unquotedString substringFromIndex: index];
        c = [temp charAtIndex: 0];

        /* Append it, too! */
        [result appendChar: c];

        /* Move unquotedString past the special character */
        temp = [[unquotedString substringFromCharset: specialChars] retain];

        [unquotedString release];
        unquotedString = temp;
    }

    /* Append the remainder, if any */
    if (unquotedString) {
        [result appendString: unquotedString];
        [unquotedString release];
    }

    [pool release];

    return (result);
}

/**
 * Return a search filter string, substituting all %s format
 * specifiers with the provided subString.
 */
- (TRString *) getFilter: (TRString *) subString {
    TRString *templateString;
    TRString *result, *part;
    TRString *quotedName;
    const char userFormat[] = "%s";
    TRAutoreleasePool *pool = [[TRAutoreleasePool alloc] init];

    /* Retain the template */
    templateString = [[_format retain] autorelease];

    /* Initialize the result */
    result = [[TRString alloc] init];

    /* Quote the sub string */
    quotedName = [self escapeForSearch: subString];

    while ((part = [templateString substringToCString: userFormat]) != NULL) {
        TRString *temp;

        /* Append everything until the first %u */
        [result appendString: part];

        /* Append the username */
        [result appendString: quotedName];

        /* Move templateString past the %u */
        temp = [templateString substringFromCString: userFormat];
        templateString = temp;
    }

    [quotedName release];

    /* Append the remainder, if any */
    if (templateString) {
        [result appendString: templateString];
    }

    [pool release];

    return [result autorelease];
}

@end
