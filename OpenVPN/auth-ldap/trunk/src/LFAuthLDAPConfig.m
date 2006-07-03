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

# if 0
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
#endif

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
	TRConfig *config = NULL;
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

	/* Initialize the config parser */
	config = [[TRConfig alloc] initWithFD: configFD
				 configDelegate: self];
	if (config == NULL)
		goto error;

	/* Parse the configuration file */
	if (![config parseConfig])
		goto error;

	[config release];

	return self;

error:
	if (config)
		[config release];

	[self release];
	return (NULL);
}

- (bool) parseToken: (TRConfigToken *) token {
	fprintf(stderr, "Parsing a token ...\n");
	return YES;
}

- (bool) setKey: (TRConfigToken *) key value: (TRConfigToken *) value {
	fprintf(stderr, "Setting key\n");
	return YES;
}

- (bool) startSection: (TRConfigToken *) sectionType sectionName: (TRConfigToken *) name {
	fprintf(stderr, "Starting section\n");
	return YES;
}

- (bool) endSection: (TRConfigToken *) sectionEnd {
	fprintf(stderr, "Ending section\n");
	return YES;
}

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
