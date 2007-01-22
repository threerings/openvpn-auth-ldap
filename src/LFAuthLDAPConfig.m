/*
 * LFAuthLDAPConfig.m
 * Simple Configuration
 *
 * Copyright (c) 2005 - 2006 Landon Fuller <landonf@threerings.net>
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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include <assert.h>

#include "LFAuthLDAPConfig.h"
#include "TRLDAPGroupConfig.h"
#include "LFString.h"
#include "TRHash.h"
#include "TRLog.h"

#include "auth-ldap.h"

/* All Variables and Section Types */
typedef enum {
	/* All Section Types */
	LF_NO_SECTION,			/* Top-level */
	LF_LDAP_SECTION,		/* LDAP Server Settings */
	LF_AUTH_SECTION,		/* LDAP Authorization Settings */
	LF_GROUP_SECTION,		/* LDAP Group Settings */

	/* Generic LDAP Search Variables */
	LF_LDAP_BASEDN,			/* Base DN for Search */
	LF_LDAP_SEARCH_FILTER,		/* Search Filter */

	/* Generic PF Variables */
	LF_AUTH_PFTABLE,		/* PF Table Name */

	/* LDAP Section Variables */
	LF_LDAP_URL,			/* LDAP Server URL */
	LF_LDAP_TIMEOUT,		/* LDAP Server Timeout */
	LF_LDAP_BINDDN,			/* Bind DN for LDAP Searches */
	LF_LDAP_PASSWORD,		/* Associated Password */
	LF_LDAP_REFERRAL,		/* Enable Referrals */
	LF_LDAP_TLS,			/* Enable TLS */
	LF_LDAP_TLS_CA_CERTFILE,	/* TLS CA Certificate File */
	LF_LDAP_TLS_CA_CERTDIR,		/* TLS CA Certificate Dir */
	LF_LDAP_TLS_CERTFILE,		/* TLS Client Certificate File */
	LF_LDAP_TLS_KEYFILE,		/* TLS Client Key File */
	LF_LDAP_TLS_CIPHER_SUITE,	/* TLS Cipher Suite */

	/* Authorization Section Variables */
	LF_AUTH_REQUIRE_GROUP,		/* Require Group Membership */

	/* Group Section Variables */
	LF_GROUP_MEMBER_ATTRIBUTE,	/* Group Membership Attribute */

	/* Misc Shared */
	LF_UNKNOWN_OPCODE,		/* Unknown Opcode */
} ConfigOpcode;


typedef struct OpcodeTable {
	const char *name;
	ConfigOpcode opcode;
	BOOL multi;
	BOOL required;
} OpcodeTable;

/* Section Types */
static OpcodeTable SectionTypes[] = {
	/* name			opcode			multi	required */
	{ "LDAP",		LF_LDAP_SECTION, 	NO,	YES },
	{ "Authorization",	LF_AUTH_SECTION, 	NO,	YES },
	{ "Group",		LF_GROUP_SECTION, 	YES,	NO },
	{ NULL, 0 }
};

/* Generic LDAP Search Variables */
static OpcodeTable GenericLDAPVariables[] = {
	/* name			opcode			multi	required */
	{ "BaseDN",		LF_LDAP_BASEDN,		NO,	YES },
	{ "SearchFilter",	LF_LDAP_SEARCH_FILTER,	NO,	YES },
	{ NULL, 0 }
};

/* Generic PF Table Variables */
static OpcodeTable GenericPFVariables[] = {
	/* name			opcode			multi	required */
#ifdef HAVE_PF
	{ "PFTable",		LF_AUTH_PFTABLE,	NO,	NO },
#endif
	{ NULL, 0 }
};

/* LDAP Section Variables */
static OpcodeTable LDAPSectionVariables[] = {
	/* name			opcode			multi	required */
	{ "URL",		LF_LDAP_URL,		NO,	YES },
	{ "Timeout",		LF_LDAP_TIMEOUT,	NO,	NO },
	{ "BindDN",		LF_LDAP_BINDDN,		NO,	NO },
	{ "Password",		LF_LDAP_PASSWORD,	NO,	NO },
	{ "FollowReferrals",	LF_LDAP_REFERRAL,	NO,	NO },
	{ "TLSEnable",		LF_LDAP_TLS,		NO,	NO },
	{ "TLSCACertFile",	LF_LDAP_TLS_CA_CERTFILE, NO,	NO },
	{ "TLSCACertDir",	LF_LDAP_TLS_CA_CERTDIR,	NO,	NO },
	{ "TLSCertFile",	LF_LDAP_TLS_CERTFILE,	NO,	NO },
	{ "TLSKeyFile",		LF_LDAP_TLS_KEYFILE,	NO,	NO },
	{ "TLSCipherSuite",	LF_LDAP_TLS_CIPHER_SUITE, NO,	NO },
	{ NULL, 0 }
};

/* Authorization Section Variables */
static OpcodeTable AuthSectionVariables[] = {
	/* name			opcode			multi	required */
	{ "RequireGroup",	LF_AUTH_REQUIRE_GROUP,	NO,	NO },
	{ NULL, 0}
};

/* Group Section Variables */
static OpcodeTable GroupSectionVariables[] = {
	/* name			opcode			multi	required */
	{ "MemberAttribute",	LF_GROUP_MEMBER_ATTRIBUTE, NO,	NO },
	{ NULL, 0 }
};

/* Section Types */
static OpcodeTable *Sections[] = {
	SectionTypes,
	NULL
};

/* LDAP Section Definition */
static OpcodeTable *LDAPSection[] = {
	LDAPSectionVariables,
	NULL
};

/* Auth Section Definition */
static OpcodeTable *AuthSection[] = {
	AuthSectionVariables,
	GenericLDAPVariables,
	GenericPFVariables,
	NULL
};

/* Group Section Definition */
static OpcodeTable *GroupSection[] = {
	GroupSectionVariables,
	GenericLDAPVariables,
	GenericPFVariables,
	NULL
};

/* Parse a string, returning the associated entry from the supplied table */
static OpcodeTable *parse_opcode (TRConfigToken *token, OpcodeTable **tables) {
	const char *cp = [token cString];
	OpcodeTable *table, **p;
	unsigned int i;

	for (p = tables; *p; p++) {
		table = *p;
		for (i = 0; table[i].name; i++)
			if (strcasecmp(cp, table[i].name) == 0)
				return (&table[i]);
	}

	/* Unknown opcode */
	return (NULL);
}

/* Parse a string, returning the associated opcode from the supplied table */
static const char *string_for_opcode(ConfigOpcode opcode, OpcodeTable *tables[]) {
	OpcodeTable *table, **p;
	unsigned int i;

	for (p = tables; *p; p++) {
		table = *p;
		for (i = 0; table[i].name; i++)
			if (table[i].opcode == opcode)
				return (table[i].name);
	}

	/* Unknown opcode */
	return (NULL);
}



/*
 * Simple object that maintains section parsing state
 */
@interface SectionState : TRObject {
	ConfigOpcode _opcode;
	TRHash *_hash;
	id _context;
}

@end

@implementation SectionState
- (void) dealloc {
	[_hash release];
	if (_context)
		[_context release];
	[super dealloc];
}

- (id) init {
	self = [super init];
	if (!self)
		return self;

	_opcode = LF_UNKNOWN_OPCODE;
	/* Totally arbitrary number. More keys than this will cause assert() to trigger */
	_hash = [[TRHash alloc] initWithCapacity: 65536];

	return self;
}

- (id) initWithOpcode: (ConfigOpcode) anOpcode {
	if ([self init])
		_opcode = anOpcode;

	return self;
}

- (ConfigOpcode) opcode {
	return _opcode;
}

- (TRHash *) hashTable {
	return _hash;
}

- (void) setContext: (id) context {
	if (_context)
		[_context release];
	_context = [context retain];
}

- (id) context {
	return _context;
}

@end

@implementation LFAuthLDAPConfig

- (void) dealloc {
	if (_url)
		[_url release];
	if (_bindDN)
		[_bindDN release];
	if (_bindPassword)
		[_bindPassword release];
	if (_tlsCACertFile)
		[_tlsCACertFile release];
	if (_tlsCACertDir)
		[_tlsCACertDir release];
	if (_tlsCertFile)
		[_tlsCertFile release];
	if (_tlsKeyFile)
		[_tlsKeyFile release];
	if (_tlsCipherSuite)
		[_tlsCipherSuite release];
	if (_baseDN)
		[_baseDN release];
	if (_searchFilter)
		[_searchFilter release];
	if (_ldapGroups)
		[_ldapGroups release];
	if (_pfTable)
		[_pfTable release];

	[super dealloc];
}

- (id) initWithConfigFile: (const char *) fileName {
	SectionState *section;
	int configFD;

	/* Initialize */
	self = [self init];

	if (self == NULL)
		return (self);

	/* Initialize the section stack */
	_sectionStack = [[TRArray alloc] init];
	section = [[SectionState alloc] initWithOpcode: LF_NO_SECTION];
	[_sectionStack addObject: section];
	[section release];

	/* Open our configuration file */
	_configFileName = [[LFString alloc] initWithCString: fileName];
	configFD = open(fileName, O_RDONLY);
	if (configFD == -1) {
		[TRLog error: "Failed to open \"%s\" for reading", [_configFileName cString]];
		goto error;
	}

	/* Initialize the config parser */
	_configDriver = [[TRConfig alloc] initWithFD: configFD
				 configDelegate: self];
	if (_configDriver == NULL)
		goto error;

	/* Parse the configuration file */
	if (![_configDriver parseConfig])
		goto error;

	[_configDriver release];
	[_sectionStack release];
	[_configFileName release];

	return self;

error:
	if (_configDriver)
		[_configDriver release];
	if (_sectionStack)
		[_sectionStack release];
	if (_configFileName)
		[_configFileName release];

	[self release];
	return (NULL);
}

/*!
 * Return the current section opcode from the top
 * of the section stack.
 */
- (ConfigOpcode) currentSectionOpcode {
	return [[_sectionStack lastObject] opcode];
}

/*!
 * Return the current section's hash table.
 */
- (TRHash *) currentSectionHashTable {
	return [[_sectionStack lastObject] hashTable];
}

/*!
 * Return the current section's context.
 */
- (id) currentSectionContext {
	return [[_sectionStack lastObject] context];
}

/*!
 * Set the current section's context.
 */
- (void) setCurrentSectionContext: (id) context {
	[[_sectionStack lastObject] setContext: context];
}

/*!
 * Allocate a SectionState object and push it onto the
 * section stack.
 */
- (void) pushSection: (ConfigOpcode) opcode {
	SectionState *section;

	section = [[SectionState alloc] initWithOpcode: opcode];
	[_sectionStack addObject: section];
	[section release];
}

/*!
 * Report a named section that should not be named to the user.
 */
- (void) errorNamedSection: (TRConfigToken *) section withName: (TRConfigToken *) name {
	[TRLog error: "Auth-LDAP Configuration Error: %s section types must be unnamed (%s:%u).", [section cString], [_configFileName cString], [name lineNumber]];
	[_configDriver errorStop];
}

/*!
 * Report an unknown key to the user.
 */
- (void) errorUnknownKey: (TRConfigToken *) key {
	[TRLog error: "Auth-LDAP Configuration Error: %s key is unknown (%s:%u).", [key cString], [_configFileName cString], [key lineNumber]];
	[_configDriver errorStop];
}

/*!
 * Report a duplicate key to the user.
 */
- (void) errorMultiKey: (TRConfigToken *) key {
	[TRLog error: "Auth-LDAP Configuration Error: multiple occurances of key %s (%s:%u).", [key cString], [_configFileName cString], [key lineNumber]];
	[_configDriver errorStop];
}

/*!
 * Report an invalid integer value to the user.
 */
- (void) errorIntValue: (TRConfigToken *) value {
	[TRLog error: "Auth-LDAP Configuration Error: %s value is not an integer (%s:%u).", [value cString], [_configFileName cString], [value lineNumber]];
	[_configDriver errorStop];
}

/*!
 * Report an invalid boolean value to the user.
 */
- (void) errorBoolValue: (TRConfigToken *) value {
	[TRLog error: "Auth-LDAP Configuration Error: %s value is not a boolean value -- use either 'True' or 'False' (%s:%u).", [value cString], [_configFileName cString], [value lineNumber]];
	[_configDriver errorStop];
}

/*!
 * Report an unknown section type to the user.
 */
- (void) errorUnknownSection: (TRConfigToken *) section {
	[TRLog error: "Auth-LDAP Configuration Error: %s is not a known section type within this context (%s:%u).",
			[section cString], [_configFileName cString], [section lineNumber]];
	[_configDriver errorStop];
}

/*!
 * Report mismatched section closure to the user.
 */
- (void) errorMismatchedSection: (TRConfigToken *) section {
	[TRLog error: "Auth-LDAP Configuration Error: '</%s>' is a mismatched section closure. Expected \"</%s>\" (%s:%u).",
			[section cString], string_for_opcode([self currentSectionOpcode], Sections),
			[_configFileName cString], [section lineNumber]];
	[_configDriver errorStop];
}

/*!
 * Check for any missing required variables and report them to the user.
 * @return YES on success, NO on failure.
 */
- (BOOL) validateRequiredVariables: (OpcodeTable **) tables withSectionEnd: (TRConfigToken *) section {
	OpcodeTable *table, **p;
	unsigned int i;

	for (p = tables; *p; p++) {
		table = *p;
		for (i = 0; table[i].name; i++) {
			if (table[i].required) {
				LFString *key = [[LFString alloc] initWithCString: table[i].name];
				if ([[self currentSectionHashTable] valueForKey: key] == nil) {
					[TRLog error: "Auth-LDAP Configuration Error: Section %s is a missing required key '%s' (%s:%u).",
						string_for_opcode([self currentSectionOpcode], Sections), table[i].name, [_configFileName cString], [section lineNumber]];
					[key release];
					[_configDriver errorStop];
					return NO;
				}
				[key release];
			}
		}
	}
	return YES;
}



/*!
 * Called by the lemon generated parser when a new section is found.
 */
- (void) startSection: (TRConfigToken *) sectionType sectionName: (TRConfigToken *) name {
	OpcodeTable *opcodeEntry;

	/* Parse the section opcode */
	opcodeEntry = parse_opcode(sectionType, Sections);

	/* Enter handler for the current state */
	switch([self currentSectionOpcode]) {
		/* Top-level sections supported:
		 * 	- LDAP (unnamed)
		 * 	- Group (named)
		 */
		case LF_NO_SECTION:
			switch (opcodeEntry->opcode) {
				case LF_LDAP_SECTION:
					if (name) {
						[self errorNamedSection: sectionType withName: name];
						return;
					}
					[self pushSection: opcodeEntry->opcode];
					break;
				case LF_AUTH_SECTION:
					if (name) {
						[self errorNamedSection: sectionType withName: name];
						return;
					}
					[self pushSection: opcodeEntry->opcode];
					break;
				default:
					[self errorUnknownSection: sectionType];
					return;
			}
			break;
		case LF_AUTH_SECTION:
			/* Currently, no named sections are supported */
			if (name) {
				[self errorNamedSection: sectionType withName: name];
				return;
			}

			/* Validate the section type */
			switch (opcodeEntry->opcode) {
				TRLDAPGroupConfig *groupConfig;
				case LF_GROUP_SECTION:
					groupConfig = [[TRLDAPGroupConfig alloc] init];
					[self pushSection: opcodeEntry->opcode];
					[self setCurrentSectionContext: groupConfig];
					if (!_ldapGroups) {
						_ldapGroups = [[TRArray alloc] init];
					}
					/* Let the SectionContext own groupConfig */
					[groupConfig release];
					break;
				default:
					[self errorUnknownSection: sectionType];
					return;
			}
			break;
		default:
			[self errorUnknownSection: sectionType];
			return;
	}

	return;
}

/*!
 * Called by the lemon-generated parser when a key value pair is found.
 */
- (void) setKey: (TRConfigToken *) key value: (TRConfigToken *) value {
	/* Handle key value pairs */
	OpcodeTable *opcodeEntry;
	TRHash *hashTable = [self currentSectionHashTable];

	switch ([self currentSectionOpcode]) {
		case LF_NO_SECTION:
			/* No keys are permitted in the top-level */
			[self errorUnknownKey: key];
			return;

		case LF_LDAP_SECTION:
			opcodeEntry = parse_opcode(key, LDAPSection);
			if (!opcodeEntry) {
				[self errorUnknownKey: key];
				return;
			}
			switch (opcodeEntry->opcode) {
				int timeout;
				BOOL enableTLS;
				BOOL enableReferral;

				/* LDAP URL */
				case LF_LDAP_URL:
					[self setURL: [value string]];
					break;

				/* LDAP Bind DN */
				case LF_LDAP_BINDDN:
					[self setBindDN: [value string]];
					break;

				/* LDAP Bind Password */
				case LF_LDAP_PASSWORD:
					[self setBindPassword: [value string]];
					break;

				/* LDAP Connection Timeout */
				case LF_LDAP_TIMEOUT:
					if (![value intValue: &timeout]) {
						[self errorIntValue: value];
						return;
					}
					[self setTimeout: timeout];
					break;

				/* LDAP Referrals Enabled */
				case LF_LDAP_REFERRAL:
					if (![value boolValue: &enableReferral]) {
						[self errorBoolValue: value];
						return;
					}
					[self setReferralEnabled: enableReferral];
					break;

				/* LDAP TLS Enabled */
				case LF_LDAP_TLS:
					if (![value boolValue: &enableTLS]) {
						[self errorBoolValue: value];
						return;
					}
					[self setTLSEnabled: enableTLS];
					break;

				/* LDAP CA Certificate */
				case LF_LDAP_TLS_CA_CERTFILE:
					[self setTLSCACertFile: [value string]];
					break;

				/* LDAP CA Certificate Directory */
				case LF_LDAP_TLS_CA_CERTDIR:
					[self setTLSCACertDir: [value string]];
					break;

				/* LDAP Certificate File */
				case LF_LDAP_TLS_CERTFILE:
					[self setTLSCertFile: [value string]];
					break;

				/* LDAP Key File */
				case LF_LDAP_TLS_KEYFILE:
					[self setTLSKeyFile: [value string]];
					break;

				/* TLS Cipher Suite */
				case LF_LDAP_TLS_CIPHER_SUITE:
					[self setTLSCipherSuite: [value string]];
					break;

				/* Unknown Setting */
				default:
					[self errorUnknownKey: key];
					return;
			}
			break;

		case LF_AUTH_SECTION:
			opcodeEntry = parse_opcode(key, AuthSection);
			if (!opcodeEntry) {
				[self errorUnknownKey: key];
				return;
			}

			switch(opcodeEntry->opcode) {
				BOOL requireGroup;

				case LF_AUTH_REQUIRE_GROUP:
					if (![value boolValue: &requireGroup]) {
						[self errorBoolValue: value];
						return;
					}
					[self setRequireGroup: requireGroup];
					break;

				case LF_LDAP_BASEDN:
					[self setBaseDN: [value string]];
					break;

				case LF_LDAP_SEARCH_FILTER:
					[self setSearchFilter: [value string]];
					break;

				case LF_AUTH_PFTABLE:
					[self setPFTable: [value string]];
					[self setPFEnabled: YES];
					break;

				/* Unknown Setting */
				default:
					[self errorUnknownKey: key];
					return;
			}
			break;
		case LF_GROUP_SECTION:
			opcodeEntry = parse_opcode(key, GroupSection);
			if (!opcodeEntry) {
				[self errorUnknownKey: key];
				return;
			}

			switch(opcodeEntry->opcode) {
				TRLDAPGroupConfig *config;

				case LF_GROUP_MEMBER_ATTRIBUTE:
					config = [self currentSectionContext];
					[config setMemberAttribute: [value string]];
					break;

				case LF_LDAP_BASEDN:
					config = [self currentSectionContext];
					[config setBaseDN: [value string]];
					break;

				case LF_LDAP_SEARCH_FILTER:
					config = [self currentSectionContext];
					[config setSearchFilter: [value string]];
					break;

				case LF_AUTH_PFTABLE:
					config = [self currentSectionContext];
					[config setPFTable: [value string]];
					[self setPFEnabled: YES];
					break;

				/* Unknown Setting */
				default:
					[self errorUnknownKey: key];
			}
			break;
		default:
			/* Must be unreachable! */
			[TRLog error: "Unhandled section type in setKey!\n"];
			abort();
			break;
	}

	/* Lastly, prevent multiple occurances of a single-use key */
	if (!opcodeEntry->multi) {
		if ([hashTable valueForKey: [key string]]) {
			[self errorMultiKey: key];
			return;
		}
		[hashTable setObject: value forKey: [key string]];
	}
}

/*!
 * Verify that the now closed section isn't mismatched, and then pop it off
 * the section stack.
 */
- (void) endSection: (TRConfigToken *) sectionEnd {
	OpcodeTable *opcodeEntry;
	opcodeEntry = parse_opcode(sectionEnd, Sections);

	/* Mismatched section? */
	if (!opcodeEntry || opcodeEntry->opcode != [self currentSectionOpcode]) {
		[self errorMismatchedSection: sectionEnd];
		return;
	}

	switch (opcodeEntry->opcode) {
		case LF_LDAP_SECTION:
			[self validateRequiredVariables: LDAPSection withSectionEnd: sectionEnd];
			break;
		case LF_AUTH_SECTION:
			[self validateRequiredVariables: AuthSection withSectionEnd: sectionEnd];
			break;
		case LF_GROUP_SECTION:
			/* Add the group config to the array */
			if (![self validateRequiredVariables: GroupSection withSectionEnd: sectionEnd])
				break;
			[_ldapGroups addObject: [self currentSectionContext]];
			break;
		default:
			/* Must be unreachable! */
			[TRLog error: "Unhandled section type in endSection!\n"];
			abort();
			return;

	}

	[_sectionStack removeObject];

}

- (void) parseError: (TRConfigToken *) badToken {
	if (badToken)
		[TRLog error: "A parse error occured while attempting to comprehend %s, on line %u.", [badToken cString], [badToken lineNumber]];
	else
		[TRLog error: "A parse error occured while attempting to read your configuration file."];
	[_configDriver errorStop];
}

/* Accessors */

- (BOOL) tlsEnabled {
	return (_tlsEnabled);
}

- (void) setTLSEnabled: (BOOL) newTLSSetting {
	_tlsEnabled = newTLSSetting;
}

- (LFString *) url {
	return (_url);
}

- (LFString *) bindDN {
	return (_bindDN);
}

- (void) setBindDN: (LFString *) bindDN {
	if (_bindDN)
		[_bindDN release];
	_bindDN = [bindDN retain];
}

- (LFString *) bindPassword {
	return (_bindPassword);
}

- (void) setBindPassword: (LFString *) bindPassword {
	if (_bindPassword)
		[_bindPassword release];
	_bindPassword = [bindPassword retain];
}

- (void) setURL: (LFString *) newURL {
	if (_url)
		[_url release];
	_url = [newURL retain];
}

- (LFString *) baseDN {
	return (_baseDN);
}

- (void) setBaseDN: (LFString *) baseDN {
	if (_baseDN)
		[_baseDN release];
	_baseDN = [baseDN retain];
}

- (LFString *) searchFilter {
	return (_searchFilter);
}

- (BOOL) requireGroup {
	return (_requireGroup);
}

- (void) setRequireGroup: (BOOL) requireGroup {
	_requireGroup = requireGroup;
}

- (void) setSearchFilter: (LFString *) searchFilter {
	if (_searchFilter)
		[_searchFilter release];
	_searchFilter = [searchFilter retain];
}

- (BOOL) referralEnabled {
	return (_referralEnabled);
}

- (void) setReferralEnabled: (BOOL) newReferralSetting {
	_referralEnabled = newReferralSetting;
}

- (int) timeout {
	return (_timeout);
}

- (void) setTimeout: (int) newTimeout {
	_timeout = newTimeout;
}

- (LFString *) tlsCACertFile {
	return (_tlsCACertFile);
}

- (void) setTLSCACertFile: (LFString *) fileName {
	if (_tlsCACertFile)
		[_tlsCACertFile release];
	_tlsCACertFile = [fileName retain];
}

- (LFString *) tlsCACertDir {
	return (_tlsCACertDir);
}

- (void) setTLSCACertDir: (LFString *) directoryName {
	if (_tlsCACertDir)
		[_tlsCACertDir release];
	_tlsCACertDir = [directoryName retain];
}

- (LFString *) tlsCertFile {
	return (_tlsCertFile);
}

- (void) setTLSCertFile: (LFString *) fileName {
	if (_tlsCertFile)
		[_tlsCertFile release];
	_tlsCertFile = [fileName retain];
}

- (LFString *) tlsKeyFile {
	return (_tlsKeyFile);
}

- (void) setTLSKeyFile: (LFString *) fileName {
	if (_tlsKeyFile)
		[_tlsKeyFile release];
	_tlsKeyFile = [fileName retain];
}

- (LFString *) tlsCipherSuite {
	return (_tlsCipherSuite);
}

- (void) setTLSCipherSuite: (LFString *) cipherSuite {
	if (_tlsCipherSuite)
		[_tlsCipherSuite release];
	_tlsCipherSuite = [cipherSuite retain];
}

- (void) setPFTable: (LFString *) tableName {
	if (_pfTable)
		[_pfTable release];
	_pfTable = [tableName retain];
}

- (LFString *) pfTable {
	return (_pfTable);
}


- (BOOL) pfEnabled {
	return (_pfEnabled);
}

- (void) setPFEnabled: (BOOL) newPFSetting {
	_pfEnabled = newPFSetting;
}

- (TRArray *) ldapGroups {
	return _ldapGroups;
}

@end
