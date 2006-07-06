/*
 * LFAuthLDAPConfig.m
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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <err.h>
#include <errno.h>
#include <assert.h>

#include "LFAuthLDAPConfig.h"
#include "LFString.h"

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

	/* LDAP Section Variables */
	LF_LDAP_URL,			/* LDAP Server URL */
	LF_LDAP_TIMEOUT,		/* LDAP Server Timeout */
	LF_LDAP_BINDDN,			/* Bind DN for LDAP Searches */
	LF_LDAP_PASSWORD,		/* Associated Password */
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
} OpcodeTable;

/* Section Types */
static OpcodeTable SectionTypes[] = {
	{ "LDAP",		LF_LDAP_SECTION },
	{ "Authorization",	LF_AUTH_SECTION },
	{ "Group",		LF_GROUP_SECTION },
	{ NULL, 0 }
};

/* Generic LDAP Search Variables */
static OpcodeTable GenericLDAPVariables[] = {
	{ "BaseDN",		LF_LDAP_BASEDN },
	{ "SearchFilter",	LF_LDAP_SEARCH_FILTER },
	{ NULL, 0 }
};

/* LDAP Section Variables */
static OpcodeTable LDAPSectionVariables[] = {
	{ "URL",		LF_LDAP_URL },
	{ "Timeout",		LF_LDAP_TIMEOUT },
	{ "BindDN",		LF_LDAP_BINDDN },
	{ "Password",		LF_LDAP_PASSWORD },
	{ "TLSEnable",		LF_LDAP_TLS },
	{ "TLSCACertFile",	LF_LDAP_TLS_CA_CERTFILE },
	{ "TLSCACertDir",	LF_LDAP_TLS_CA_CERTDIR },
	{ "TLSCertFile",	LF_LDAP_TLS_CERTFILE },
	{ "TLSKeyFile",		LF_LDAP_TLS_KEYFILE },
	{ "TLSCipherSuite",	LF_LDAP_TLS_CIPHER_SUITE },
	{ NULL, 0 }
};

/* Authorization Section Variables */
static OpcodeTable AuthSectionVariables[] = {
	{ "RequireGroup",	LF_AUTH_REQUIRE_GROUP },
	{ NULL, 0}
};

/* Group Section Variables */
static OpcodeTable GroupSectionVariables[] = {
	{ "MemberAttribute",	LF_GROUP_MEMBER_ATTRIBUTE },
	{ NULL, 0 }
};

/* Parse a string, returning the associated opcode from the supplied table */
static ConfigOpcode parse_opcode (TRConfigToken *token, OpcodeTable table[]) {
	unsigned int i;
	const char *cp = [token cString];

	for (i = 0; table[i].name; i++)
		if (strcasecmp(cp, table[i].name) == 0)
			return (table[i].opcode);

	/* Unknown opcode */
	return (LF_UNKNOWN_OPCODE);
}

/* Parse a string, returning the associated opcode from the supplied table */
static const char *string_for_opcode(ConfigOpcode opcode, OpcodeTable table[]) {
	unsigned int i;

	for (i = 0; table[i].name; i++)
		if (table[i].opcode == opcode)
			return (table[i].name);

	/* Unknown opcode */
	return (NULL);
}



/*
 * Simple object that maintains section parsing state
 */
@interface SectionState : TRObject {
	ConfigOpcode opcode;
}

@end

@implementation SectionState
- (id) init {
	self = [super init];
	if (self)
		opcode = LF_UNKNOWN_OPCODE;

	return self;
}

- (id) initWithOpcode: (ConfigOpcode) anOpcode {
	if ([self init])
		opcode = anOpcode;

	return self;
}

- (ConfigOpcode) opcode {
	return opcode;
}
@end

@implementation LFAuthLDAPConfig

- (void) dealloc {
	if (_url)
		[_url release];
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
		warn("Failed to open \"%s\" for reading", _configFileName);
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
	warnx("Auth-LDAP Configuration Error: %s section types must be unnamed (%s:%u).", [section cString], [_configFileName cString], [name lineNumber]); \
	[_configDriver errorStop];
}

/*!
 * Report an unknown key to the user.
 */
- (void) errorUnknownKey: (TRConfigToken *) key {
	warnx("Auth-LDAP Configuration Error: %s key is unknown (%s:%u).", [key cString], [_configFileName cString], [key lineNumber]); \
	[_configDriver errorStop];
}

/*!
 * Report an invalid integer value to the user.
 */
- (void) errorIntValue: (TRConfigToken *) value {
	warnx("Auth-LDAP Configuration Error: %s value is not an integer (%s:%u).", [value cString], [_configFileName cString], [value lineNumber]); \
	[_configDriver errorStop];
}

/*!
 * Report an invalid boolean value to the user.
 */
- (void) errorBoolValue: (TRConfigToken *) value {
	warnx("Auth-LDAP Configuration Error: %s value is not a boolean value -- use either 'True' or 'False' (%s:%u).", [value cString], [_configFileName cString], [value lineNumber]); \
	[_configDriver errorStop];
}

/*!
 * Report an unknown section type to the user.
 */
- (void) errorUnknownSection: (TRConfigToken *) section {
	warnx("Auth-LDAP Configuration Error: %s is not a known section type within this context (%s:%u).", [section cString], [_configFileName cString], [section lineNumber]); \
	[_configDriver errorStop];
}

/*!
 * Report mismatched section closure to the user.
 */
- (void) errorMismatchedSection: (TRConfigToken *) section {
	warnx("Auth-LDAP Configuration Error: '</%s>' is a mismatched section closure. Expected \"</%s>\" (%s:%u).", [section cString], string_for_opcode([self currentSectionOpcode], SectionTypes), [_configFileName cString], [section lineNumber]); \
	[_configDriver errorStop];
}


/*!
 * Called by the lemon-generated parser when a key value pair is found.
 */
- (void) setKey: (TRConfigToken *) key value: (TRConfigToken *) value {
	/* Handle key value pairs */
	ConfigOpcode opcode;

	switch ([self currentSectionOpcode]) {
		case LF_NO_SECTION:
			/* No keys are permitted in the top-level */
			[self errorUnknownKey: key];
			return;

		case LF_LDAP_SECTION:
			switch (parse_opcode(key, LDAPSectionVariables)) {
				int timeout;
				BOOL enableTLS;

				/* LDAP URL */
				case LF_LDAP_URL:
					[self setURL: [value string]];
					break;

				/* LDAP Connection Timeout */
				case LF_LDAP_TIMEOUT:
					if (![value intValue: &timeout]) {
						[self errorIntValue: value];
						return;
					}
					[self setTimeout: timeout];
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

				/* LDAP Key File */
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
			/* Opcode must be one of AuthSectionVariables or GenericLDAPVariables */
			opcode = parse_opcode(key, AuthSectionVariables);
			if (opcode == LF_UNKNOWN_OPCODE)
				opcode = parse_opcode(key, GenericLDAPVariables);

			switch(opcode) {
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

				/* Unknown Setting */
				default:
					[self errorUnknownKey: key];
					return;
			}
			break;
		default:
			/* (Must be!) unreachable */
			abort();
			break;
	}
	parse_opcode(key, GroupSectionVariables);
}

- (void) startSection: (TRConfigToken *) sectionType sectionName: (TRConfigToken *) name {
	ConfigOpcode opcode;

	/* Enter handler for the current state */
	switch([self currentSectionOpcode]) {
		/* Top-level sections supported:
		 * 	- LDAP (unnamed)
		 * 	- Group (named)
		 */
		case LF_NO_SECTION:
			opcode = parse_opcode(sectionType, SectionTypes);
			switch (opcode) {
				case LF_LDAP_SECTION:
					if (name) {
						[self errorNamedSection: sectionType withName: name];
						return;
					}
					[self pushSection: opcode];
					break;
				case LF_AUTH_SECTION:
					if (name) {
						[self errorNamedSection: sectionType withName: name];
						return;
					}
					[self pushSection: opcode];
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
 * Verify that the now closed section isn't mismatched, and then pop it off
 * the section stack.
 */
- (void) endSection: (TRConfigToken *) sectionEnd {
	ConfigOpcode opcode;
	opcode = parse_opcode(sectionEnd, SectionTypes);

	/* Mismatched section? */
	if (opcode != [self currentSectionOpcode]) {
		[self errorMismatchedSection: sectionEnd];
	}

	/* TODO: Handle missing required settings */

	[_sectionStack removeObject];

}

- (void) parseError: (TRConfigToken *) badToken {
	if (badToken)
		warnx("A parse error occured while attempting to comprehend %s, on line %u.", [badToken cString], [badToken lineNumber]);
	else
		warnx("A parse error occured while attempting to read your configuration file.");
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

@end
