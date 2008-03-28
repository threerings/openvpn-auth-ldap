/*
 * TRLDAPAccountRepository.h vi:ts=4:sw=4:expandtab:
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

#ifndef TRLDAPACCOUNTREPOSITORY_H
#define TRLDAPACCOUNTREPOSITORY_H

#include "TRObject.h"
#include "TRLDAPConnection.h"
#include "TRLDAPSearchFilter.h"

#include "TRAccountRepository.h"

#include "util/TRString.h"

/**
 * LDAP user/group account verification.
 */
@interface TRLDAPAccountRepository : TRObject <TRAccountRepository> {
@private
    TRLDAPConnection *_ldap;
    TRLDAPSearchFilter *_userFilter;
    TRLDAPSearchFilter *_groupFilter;
}

- (id) initWithLDAPConnection: (TRLDAPConnection *) ldap
             userSearchFilter: (TRLDAPSearchFilter *) userFilter
            groupSearchFilter: (TRLDAPSearchFilter *) groupFilter;
             
- (BOOL) authenticateUser: (TRString *) username withPassword: (TRString *) password;
- (BOOL) checkGroupMember: (TRString *) username withGroup: (TRString *) groupname;
@end

#endif /* TRLDAPACCOUNTREPOSITORY_H */
