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

#include "TRConfigToken.h"
#include "TRConfigLexer.h"
#include "TRConfigParser.h"

#include "auth-ldap.h"

static struct {
	const char *name;
	AuthLDAPConfigOptions opcode;
} keywords [] = {
	{ "ldap_url",		LF_LDAP_URL },
	{ "ldap_timeout",	LF_LDAP_TIMEOUT },
	{ "tls_enable",		LF_LDAP_TLS },
	{ "tls_ca_certfile",	LF_LDAP_TLS_CA_CERTFILE },
	{ "tls_ca_certdir",	LF_LDAP_TLS_CA_CERTDIR },
	{ "tls_certfile",	LF_LDAP_TLS_CERTFILE },
	{ "tls_keyfile",	LF_LDAP_TLS_KEYFILE },
	{ "tls_ciphersuite",	LF_LDAP_TLS_CIPHER_SUITE },
	{ NULL, 0 }
};

#define WHITESPACE " \t\r\n"

static AuthLDAPConfigOptions parse_opcode (const char *word, const char *filename, int linenum) {
	unsigned int i;

	for (i = 0; keywords[i].name; i++)
		if (strcasecmp(word, keywords[i].name) == 0)
			return (keywords[i].opcode);

	warnx("%s: line %d: Bad configuration option: %s", filename, linenum, word);
	return (LF_LDAP_BADOPTION);
}

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

	[super free];
}

- (LFAuthLDAPConfig *) initWithConfigFile: (const char *) fileName {
	TRConfigLexer *lexer = NULL;
	TRConfigToken *token;
	void *parser;
	int configFD;

	/* Initialize */
	self = [self init];

	if (self == NULL)
		return (self);

	/* Open our configuration file */
	configFD = open(fileName, O_RDONLY);
	if (configFD == -1) {
		warn("Failed to open \"%s\" for reading: %s", fileName, strerror(errno));
		goto error;
	}

	/* Initialize a lexer */
	lexer = [[TRConfigLexer alloc] initWithFD: configFD];
	if (lexer == NULL) {
		goto error;
	}

	/* Parse the configuration file */
	parser = TRConfigParseAlloc(malloc);
	TRConfigParseTrace(stdout, "trace: ");
	while ((token = [lexer scan]) != NULL) {
		TRConfigParse(parser, [token getTokenID], token);
		//[token dealloc];
	}
	TRConfigParse(parser, 0, NULL);
	TRConfigParseFree(parser, free);

	[lexer dealloc];

	return self;

error:
	if (lexer)
		[lexer dealloc];
	[self dealloc];
	return (NULL);
}



#if 0
	AuthLDAPConfigOptions opcode;
	char line[1024];
	FILE *config;
	char *cp;
	int linenum, bad_options;

	self = [self init];

	if (self == NULL)
		return (self);

	linenum = bad_options = 0;

	config = fopen(fileName, "r");
	if (!config) {
		warn("Failed to open \"%s\" for reading", fileName);
		return (NULL);
	}

	while (fgets(line, sizeof(line), config) != NULL) {
		char *key;
		char *val;
		int i;

		linenum++;

		cp = line + strspn(line, WHITESPACE);

		/* Blank line or comment */
		if (!*cp || *cp == '#')
			continue;

		/* Seperate into key and val */
		val = cp;
		while((key = strsep(&val, WHITESPACE)) == '\0') {
			key = val;
		}

		/* Strip trailing \n, if any */
		i = strlen(val) - 1;
		if (*(val + i) == '\n')
			*(val + i) = '\0';

		opcode = parse_opcode(key, fileName, linenum);
		switch (opcode) {
		LFString *temp;
			
			case LF_LDAP_BADOPTION:
				bad_options++;
				continue;
			case LF_LDAP_URL:
				url = xstrdup(val);
				break;
			case LF_LDAP_TIMEOUT:
				temp = [[LFString alloc] initWithCString: val];
				if(![temp intValue: &timeout]) {
					if (timeout == 0) {
						warnx("%s line %d: Non-integer setting '%s' for %s.", fileName, linenum, val, key);
					} else {
						warnx("%s line %d: Integer value %s out of range for %s setting.", fileName, linenum, val, key);
					}

					timeout = 0;	
					bad_options++;
				} else {
					if (timeout < 0) {
						warnx("%s line %d: You can not specify a negative timeout value for %s setting.", fileName, linenum, key);
					}
				}
				[temp dealloc];
				break;
			case LF_LDAP_TLS:
				if(strcmp("yes", val) == 0) {
					tlsEnabled = 1;
				} else if (strcmp("no", val) == 0) {
					tlsEnabled = 0;
				} else {
					warnx("%s line %d: Invalid setting '%s' for %s. Use either 'yes' or 'no'.", fileName, linenum, val, key);
					bad_options++;
				}
				break;

			case LF_LDAP_TLS_CA_CERTFILE:
				tlsCACertFile = xstrdup(val);
				break;

			case LF_LDAP_TLS_CA_CERTDIR:
				tlsCACertDir = xstrdup(val);
				break;

			case LF_LDAP_TLS_CERTFILE:
				tlsCertFile = xstrdup(val);
				break;

			case LF_LDAP_TLS_KEYFILE:
				tlsKeyFile = xstrdup(val);
				break;
			case LF_LDAP_TLS_CIPHER_SUITE:
				tlsCipherSuite = xstrdup(val);
				break;
			default:
				warnx("%s line %d: Missing handler for config opcode %s (%d)", fileName, linenum, key, opcode);
				break;
		}
	}
	fclose(config);

	/* Parsing failures? */	
	if (bad_options != 0) {
		[self dealloc];
		return (NULL);
	}

	return (self);
}
#endif

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
