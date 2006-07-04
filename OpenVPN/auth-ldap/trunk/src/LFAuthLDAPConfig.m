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

/* Useful Macros */
#define ERROR_NAMED(section, name) { \
	warnx("Auth-LDAP Configuration Error: %s section types must be unnamed (%s:%u).", [section cString], _configFileName, [name lineNumber]); \
	[_configDriver errorStop]; \
}

/* All Variables and Section Types */
typedef enum {
	/* All Section Types */
	LF_NO_SECTION,			/* Top-level */
	LF_LDAP_SECTION,		/* LDAP Server Settings */
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
	{ "LDAP",	LF_LDAP_SECTION },
	{ "Group",	LF_GROUP_SECTION },
	{ NULL, 0 }
};

/* Generic LDAP Search Variables */
static OpcodeTable GenericLDAPVariables[] = {
	{ "BaseDN",		LF_LDAP_BASEDN},
	{ "SearchFilter",	LF_LDAP_SEARCH_FILTER},
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

/*
 * Simple object that maintains section parsing state
 */
@interface SectionState : TRObject {
@public
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
@end

@implementation LFAuthLDAPConfig

- (void) dealloc {
	if (url)
		free(url);
	if (tlsCACertFile)
		free(tlsCACertFile);
	if (tlsCACertDir)
		free(tlsCACertDir);
	if (tlsCertFile)
		free(tlsCertFile);
	if (tlsKeyFile)
		free(tlsKeyFile);
	if (tlsCipherSuite)
		free(tlsCipherSuite);

	[super dealloc];
}

- (id) initWithConfigFile: (const char *) fileName {
	int configFD;

	/* Initialize */
	self = [self init];

	if (self == NULL)
		return (self);

	/* Initialize the section stack */
	_sectionStack = [[TRArray alloc] init];
	[_sectionStack addObject: [[SectionState alloc] initWithOpcode: LF_NO_SECTION]];

	/* Open our configuration file */
	_configFileName = fileName;
	configFD = open(_configFileName, O_RDONLY);
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
	_configFileName = NULL;

	return self;

error:
	if (_configDriver)
		[_configDriver release];

	[self release];
	return (NULL);
}

- (void) setKey: (TRConfigToken *) key value: (TRConfigToken *) value {
	parse_opcode(key, LDAPSectionVariables);
	parse_opcode(key, GenericLDAPVariables);
	parse_opcode(key, GroupSectionVariables);
}

- (void) startSection: (TRConfigToken *) sectionType sectionName: (TRConfigToken *) name {
	ConfigOpcode opcode;

	/* Enter handler for the current state */
	switch(((SectionState *) [_sectionStack lastObject])->opcode) {
		/* Top-level sections supported:
		 * 	- LDAP (unnamed)
		 * 	- Group (named)
		 */
		case LF_NO_SECTION:
			opcode = parse_opcode(sectionType, SectionTypes);
			switch (opcode) {
				case LF_LDAP_SECTION:
					printf("\nLDAP Section\n");
					if (name) {
						ERROR_NAMED(sectionType, name);
						return;
					}
					break;
				default:
					printf("\nUnknown Section %s %s\n", [sectionType cString], [name cString]);
					break;
			}
			break;
		default:
			break;
	}

	return;
}

- (void) endSection: (TRConfigToken *) sectionEnd {
	return;
}

- (void) parseError: (TRConfigToken *) badToken {
	if (badToken)
		warnx("A parse error occured while attempting to comprehend %s, on line %u.", [badToken cString], [badToken lineNumber]);
	else
		warnx("A parse error occured while attempting to read your configuration file.");
}

/* Accessors */

- (int) tlsEnabled {
	return (tlsEnabled);
}

- (void) setTLSEnabled: (int) newTLSSetting {
	tlsEnabled = newTLSSetting;
}

- (const char *) url {
	return (url);
}

- (void) setURL: (const char *) newURL {
	url = xstrdup(newURL);
}

- (int) timeout {
	return (timeout);
}

- (void) setTimeout: (int) newTimeout {
	timeout = newTimeout;
}

- (const char *) tlsCACertFile {
	return (tlsCACertFile);
}

- (void) setTLSCACertFile: (const char *) fileName {
	if (tlsCACertFile)
		free(tlsCACertFile);
	tlsCACertFile = xstrdup(fileName);
}

- (const char *) tlsCACertDir {
	return (tlsCACertDir);
}

- (void) setTLSCACertDir: (const char *) directoryName {
	if (tlsCACertDir)
		free(tlsCACertDir);
	tlsCACertDir = xstrdup(directoryName);
}

- (const char *) tlsCertFile {
	return (tlsCertFile);
}

- (void) setTLSCertFile: (const char *) fileName {
	if (tlsCertFile)
		free(tlsCertFile);
	tlsCertFile = xstrdup(fileName);
}

- (const char *) tlsKeyFile {
	return (tlsKeyFile);
}

- (void) setTLSKeyFile: (const char *) fileName {
	if (tlsKeyFile)
		free(tlsKeyFile);
	tlsKeyFile = xstrdup(fileName);
}

- (const char *) tlsCipherSuite {
	return (tlsCipherSuite);
}

- (void) setTLSCipherSuite: (const char *) cipherSuite {
	if (tlsCipherSuite)
		free(tlsCipherSuite);
	tlsCipherSuite = xstrdup(cipherSuite);
}

@end
