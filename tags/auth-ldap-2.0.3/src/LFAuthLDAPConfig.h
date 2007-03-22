/*
 * LFAuthLDAPConfig.h
 * Simple Configuration
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

#ifndef LFAUTHLDAPCONFIG_H
#define LFAUTHLDAPCONFIG_H

#include "TRObject.h"
#include "TRArray.h"
#include "TRConfig.h"

@interface LFAuthLDAPConfig : TRObject <TRConfigDelegate> {
	/* LDAP Settings */
	LFString *_url;
	BOOL _tlsEnabled;
	BOOL _referralEnabled;
	int _timeout;
	LFString *_tlsCACertFile;
	LFString *_tlsCACertDir;
	LFString *_tlsCertFile;
	LFString *_tlsKeyFile;
	LFString *_tlsCipherSuite;
	LFString *_bindDN;
	LFString *_bindPassword;

	/* Authentication / Authorization Settings */
	LFString *_baseDN;
	LFString *_searchFilter;
	BOOL _requireGroup;
	LFString *_pfTable;
	TRArray *_ldapGroups;
	BOOL _pfEnabled;

	/* Parser State */
	LFString *_configFileName;
	TRConfig *_configDriver;
	TRArray *_sectionStack;
}

- (id) initWithConfigFile: (const char *) fileName;

/* TRConfigDelegate */
- (void) setKey: (TRConfigToken *) key value: (TRConfigToken *) value;
- (void) startSection: (TRConfigToken *) sectionType sectionName: (TRConfigToken *) name;
- (void) endSection: (TRConfigToken *) sectionEnd;
- (void) parseError: (TRConfigToken *) badToken;

/* Accessors */
- (LFString *) url;
- (void) setURL: (LFString *) newURL;

- (int) timeout;
- (void) setTimeout: (int) newTimeout;

- (BOOL) tlsEnabled;
- (void) setTLSEnabled: (BOOL) newTLSSetting;

- (LFString *) tlsCACertFile;
- (void) setTLSCACertFile: (LFString *) fileName;

- (LFString *) tlsCACertDir;
- (void) setTLSCACertDir: (LFString *) directoryName;

- (LFString *) tlsCertFile;
- (void) setTLSCertFile: (LFString *) newFilename;

- (LFString *) tlsKeyFile;
- (void) setTLSKeyFile: (LFString *) fileName;

- (LFString *) tlsCipherSuite;
- (void) setTLSCipherSuite: (LFString *) cipherSuite;

- (LFString *) bindDN;
- (void) setBindDN: (LFString *) bindDN;

- (LFString *) bindPassword;
- (void) setBindPassword: (LFString *) bindPassword;

- (LFString *) baseDN;
- (void) setBaseDN: (LFString *) baseDN;

- (LFString *) searchFilter;
- (void) setSearchFilter: (LFString *) searchFilter;

- (BOOL) referralEnabled;
- (void) setReferralEnabled: (BOOL) newReferralSetting;

- (BOOL) requireGroup;
- (void) setRequireGroup: (BOOL) requireGroup;

- (LFString *) pfTable;
- (void) setPFTable: (LFString *) tableName;

- (BOOL) pfEnabled;
- (void) setPFEnabled: (BOOL) newPFSetting;

- (TRArray *) ldapGroups;

@end

#endif /* LFAUTHLDAPCONFIG_H */
