/*
 * LFLDAPConnection.m
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

#include <stdlib.h>
#include <string.h>
#include <err.h>

#include "LFLDAPConnection.h"

#include "auth-ldap.h"

static int ldap_get_errno(LDAP *ld) {
	int err;
	if (ldap_get_option(ld, LDAP_OPT_ERROR_NUMBER, &err) != LDAP_OPT_SUCCESS)
		err = LDAP_OTHER;
	return err;
}

static int ldap_set_tls_options(LFAuthLDAPConfig *config) {
	int err;
	if ([config tlsCACertFile]) {
		if ((err = ldap_set_option(NULL, LDAP_OPT_X_TLS_CACERTFILE, [config tlsCACertFile])) != LDAP_SUCCESS) {
			warnx("Unable to set tlsCACertFile to %s: %d: %s", [config tlsCACertFile], err, ldap_err2string(err));
			return (0);
		}
        }

	if ([config tlsCACertDir]) {
		if ((err = ldap_set_option(NULL, LDAP_OPT_X_TLS_CACERTDIR, [config tlsCACertDir])) != LDAP_SUCCESS) {
			warnx("Unable to set tlsCACertDir to %s: %d: %s", [config tlsCACertDir], err, ldap_err2string(err));
			return (0);
		}
        }

	if ([config tlsCertFile]) {
		if ((err = ldap_set_option(NULL, LDAP_OPT_X_TLS_CERTFILE, [config tlsCertFile])) != LDAP_SUCCESS) {
			warnx("Unable to set tlsCertFile to %s: %d: %s", [config tlsCertFile], err, ldap_err2string(err));
			return (0);
		}
        }

	if ([config tlsKeyFile]) {
		if ((err = ldap_set_option(NULL, LDAP_OPT_X_TLS_KEYFILE, [config tlsKeyFile])) != LDAP_SUCCESS) {
			warnx("Unable to set tlsKeyFile to %s: %d: %s", [config tlsKeyFile], err, ldap_err2string(err));
			return (0);
		}
        }

	if ([config tlsCipherSuite]) {
		if ((err = ldap_set_option(NULL, LDAP_OPT_X_TLS_KEYFILE, [config tlsCipherSuite])) != LDAP_SUCCESS) {
			warnx("Unable to set tlsCipherSuite to %s: %d: %s", [config tlsCipherSuite], err, ldap_err2string(err));
			return (0);
		}
        }
	
	return (1);
}

@implementation LFLDAPConnection

- (void) dealloc {
	[config dealloc];
	[super free];
}

- (id) initWithConfig: (LFAuthLDAPConfig *) ldapConfig {
	self = [self init];
	if (!self)
		return NULL;

	config = ldapConfig;

	/* Set up TLS */
	ldap_set_tls_options(config);

	ldap_initialize(&ldapConn, [config url]);

	if (!ldapConn) {
		warnx("Unable to initialize LDAP server %s", [config url]);
		return (NULL);
	}

	return (self);
}

@end
