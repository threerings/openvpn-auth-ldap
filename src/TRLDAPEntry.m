/*
 * TRLDAPEntry.m vi:ts=4:sw=4:expandtab:
 * LDAP Entry
 *
 * Author: Landon Fuller <landonf@threerings.net>
 *
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

#import "TRLDAPEntry.h"

/**
 * An LDAP entry.
 */
@implementation TRLDAPEntry

- (id) initWithDN: (TRString *) dn attributes: (TRHash *) attributes {
    self = [self init];
    if (!self)
        return self;

    _dn = [dn retain];
    _rdn = nil;
    _attributes = [attributes retain];

    return self;
}

- (void) dealloc {
    [_dn release];
    [_rdn release];
    [_attributes release];
    [super dealloc];
}

/**
 * Returns the entry's distinguished name.
 */
- (TRString *) dn {
    return _dn;
}

- (TRString *) rdn {
    return _rdn;
}

- (void) setRDN: (TRString *) rdn {
    _rdn=rdn;
}

/**
 * Return the entries' attributes as a dictionary.
 */
- (TRHash *) attributes {
    return _attributes;
}

@end
