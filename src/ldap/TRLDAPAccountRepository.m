/*
 * TRLDAPAccountRepository.m vi:ts=4:sw=4:expandtab:
 *
 * Author: Landon Fuller <landonf@threerings.net>
 *
 * Copyright (c) 2008 Three Rings Design, Inc.
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

#include "TRLDAPAccountRepository.h"

@implementation TRLDAPAccountRepository

/**
 * Initialize a new TRLDAPAccountRepository instance with the provided
 * TRLDAPConnection.
 */
- (id) initWithLDAPConnection: (TRLDAPConnection *) ldap {
    /* Initialize our superclass */
    self = [super init];
    if (self == nil)
        return nil;

    /* Save a reference to the LDAP connection */
    _ldap = [ldap retain];

    return self;
}

- (void) dealloc {
    /* Release our LDAP connection. */
    [_ldap release];

    /* Deallocate the superclass */
    [super dealloc];
}

/** 
 * Authenticate a user with the provided username and password.
 * From TRAccountRepository protocol.
 */
- (BOOL) authenticateUser: (TRString *) username withPassword: (TRString *) password {
    return NO;
}

/**
 * Check if the given username is a member of a group.
 * From TRAccountRepository protocol.
 */
- (BOOL) checkGroupMember: (TRString *) username withGroup: (TRString *) groupname {
    return NO;
}

@end
