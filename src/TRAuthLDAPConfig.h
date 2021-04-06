/*
 * TRAuthLDAPConfig.h vi:ts=4:sw=4:expandtab:
 * Simple Configuration
 *
 * Copyright (c) 2005 - 2007 Landon Fuller <landonf@threerings.net>
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

#import "TRObject.h"

#import "TRLDAPGroupConfig.h"

#import "TRConfig.h"
#import "TRString.h"
#import "TRArray.h"

@interface TRAuthLDAPConfig : TRObject <TRConfigDelegate> {
@private
    /* LDAP Settings */
    TRString *_url;
    BOOL _tlsEnabled;
    BOOL _referralEnabled;
    int _timeout;
    TRString *_tlsCACertFile;
    TRString *_tlsCACertDir;
    TRString *_tlsCertFile;
    TRString *_tlsKeyFile;
    TRString *_tlsCipherSuite;
    TRString *_bindDN;
    TRString *_bindPassword;

    /* Authentication / Authorization Settings */
    TRString *_baseDN;
    TRString *_searchFilter;
    BOOL _requireGroup;
    BOOL _useCn;
    TRString *_pfTable;
    TRArray *_ldapGroups;
    BOOL _pfEnabled;
	BOOL _passwordISCR;

    /* Parser State */
    TRString *_configFileName;
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
- (TRString *) url;
- (void) setURL: (TRString *) newURL;

- (int) timeout;
- (void) setTimeout: (int) newTimeout;

- (BOOL) tlsEnabled;
- (void) setTLSEnabled: (BOOL) newTLSSetting;

- (TRString *) tlsCACertFile;
- (void) setTLSCACertFile: (TRString *) fileName;

- (TRString *) tlsCACertDir;
- (void) setTLSCACertDir: (TRString *) directoryName;

- (TRString *) tlsCertFile;
- (void) setTLSCertFile: (TRString *) newFilename;

- (TRString *) tlsKeyFile;
- (void) setTLSKeyFile: (TRString *) fileName;

- (TRString *) tlsCipherSuite;
- (void) setTLSCipherSuite: (TRString *) cipherSuite;

- (TRString *) bindDN;
- (void) setBindDN: (TRString *) bindDN;

- (TRString *) bindPassword;
- (void) setBindPassword: (TRString *) bindPassword;

- (TRString *) baseDN;
- (void) setBaseDN: (TRString *) baseDN;

- (TRString *) searchFilter;
- (void) setSearchFilter: (TRString *) searchFilter;

- (BOOL) referralEnabled;
- (void) setReferralEnabled: (BOOL) newReferralSetting;

- (BOOL) requireGroup;
- (void) setRequireGroup: (BOOL) requireGroup;

- (BOOL) useCn;
- (void) setUseCn: (BOOL) useCn;

- (TRString *) pfTable;
- (void) setPFTable: (TRString *) tableName;

- (BOOL) pfEnabled;
- (void) setPFEnabled: (BOOL) newPFSetting;

- (TRArray *) ldapGroups;

- (BOOL) passWordIsCR;
- (void) setPassWordIsCR: (BOOL)newCRSetting;

@end
