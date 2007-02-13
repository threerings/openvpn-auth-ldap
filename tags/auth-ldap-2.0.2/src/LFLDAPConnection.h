/*
 * LFLDAPConnection.h
 * Simple LDAP Wrapper
 *
 * Copyright (c) 2005 Landon Fuller <landonf@threerings.net>
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

#ifndef LFLDAPCONNECTION_H
#define LFLDAPCONNECTION_H

#include <ldap.h>

#include "TRObject.h"
#include "TRArray.h"
#include "TRHash.h"
#include "TRLDAPEntry.h"
#include "LFString.h"

@interface LFLDAPConnection : TRObject {
	LDAP *ldapConn;
	int _timeout;
}

- (id) initWithURL: (LFString *) url timeout: (int) timeout;
- (BOOL) startTLS;

- (BOOL) bindWithDN: (LFString *) bindDN password: (LFString *) password;

- (TRArray *) searchWithFilter: (LFString *) filter
			 scope: (int) scope
			baseDN: (LFString *) base
		    attributes: (TRArray *) attributes;
- (BOOL) compareDN: (LFString *) dn withAttribute: (LFString *) attribute value: (LFString *) value;

- (BOOL) setReferralEnabled: (BOOL) enabled;
- (BOOL) setTLSCACertFile: (LFString *) fileName;
- (BOOL) setTLSCACertDir: (LFString *) directory;
- (BOOL) setTLSClientCert: (LFString *) certFile keyFile: (LFString *) keyFile;
- (BOOL) setTLSCipherSuite: (LFString *) cipherSuite;

@end

#endif /* LFLDAPCONNECTION_H */
