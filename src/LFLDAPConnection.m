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
#include <sys/time.h>

#include "LFLDAPConnection.h"

#include "auth-ldap.h"

static int ldap_get_errno(LDAP *ld) {
	int err;
	if (ldap_get_option(ld, LDAP_OPT_ERROR_NUMBER, &err) != LDAP_OPT_SUCCESS)
		err = LDAP_OTHER;
	return err;
}

@implementation LFLDAPConnection

- (id) initWithURL: (LFString *) url timeout: (int) timeout {
	struct timeval ldapTimeout;
	int arg;
	// int err;

	self = [self init];
	if (!self)
		return NULL;

	ldap_initialize(&ldapConn, [url cString]);

	if (!ldapConn) {
		warnx("Unable to initialize LDAP server %s", [url cString]);
		[self release];
		return (NULL);
	}

	_timeout = timeout;

	ldapTimeout.tv_sec = _timeout;
	ldapTimeout.tv_usec = 0;

	if (ldap_set_option(ldapConn, LDAP_OPT_NETWORK_TIMEOUT, &ldapTimeout) != LDAP_OPT_SUCCESS)
		warnx("Unable to set LDAP network timeout.");

	arg = LDAP_VERSION3;
	if (ldap_set_option(ldapConn, LDAP_OPT_PROTOCOL_VERSION, &arg) != LDAP_OPT_SUCCESS) {
		warnx("Unable to enable LDAPv3.");
		[self release];
		return (NULL);
	}

	return (self);
}

/*!
 * Start TLS on the LDAP connection.
 */
- (BOOL) startTLS {
	int err;
	err = ldap_start_tls_s(ldapConn, NULL, NULL);
	if (err != LDAP_SUCCESS) {
		warnx("Unable to enable STARTTLS: %s", ldap_err2string(err));
		return (NO);
	}

	return (YES);
}

- (BOOL) bindWithDN: (const char *) bindDN password: (const char *) password {
	int msgid, err;
	LDAPMessage *res;
	struct berval cred;
	struct timeval timeout;

	/* Set up berval structure for our credentials */
	cred.bv_val = (char *) password;
	cred.bv_len = strlen(password);

	if ((msgid = ldap_sasl_bind_s(ldapConn,
					bindDN,
					LDAP_SASL_SIMPLE,
					&cred,
					NULL,
					NULL,
					NULL)) == -1) {
		err = ldap_get_errno(ldapConn);
		warnx("ldap_bind failed immediately: %s", ldap_err2string(err));
		return (false);
	}

	timeout.tv_sec = _timeout;
	timeout.tv_usec = 0;

	if (ldap_result(ldapConn, msgid, 1, &timeout, &res) == -1) {
		err = ldap_get_errno(ldapConn);
		if (err == LDAP_TIMEOUT)
			ldap_abandon_ext(ldapConn, msgid, NULL, NULL);
		warnx("ldap_bind failed: %s\n", ldap_err2string(err));
		return (false);
	}

	/* TODO: Provide more diagnostics when a logging API is available */
	ldap_parse_result(ldapConn, res, &err, NULL, NULL, NULL, NULL, 1);
	if (err == LDAP_SUCCESS)
		return (true);

	return (false);
}

- (BOOL) unbind {
	int err;
	err = ldap_unbind_ext_s(ldapConn, NULL, NULL);
	if (err != LDAP_SUCCESS) {
		warnx("Unable to unbind from LDAP server: %s", ldap_err2string(err));
		return (false);
	}
	return (true);
}

- (BOOL) _setLDAPOption: (int) opt value: (const void *) value connection: (LDAP *) ldapConn {
	int err;
	if ((err = ldap_set_option(NULL, opt, value)) != LDAP_SUCCESS) {
		warnx("Unable to set ldap option %d to %s: %d: %s", opt, value, err, ldap_err2string(err));
		return (false);
	}
	return true;
}

/* Always require a valid certificate */	
- (BOOL) _setTLSRequireCert {
	int err;
	int arg;
	arg = LDAP_OPT_X_TLS_HARD;
	if ((err = ldap_set_option(NULL, LDAP_OPT_X_TLS_REQUIRE_CERT, &arg)) != LDAP_SUCCESS) {
		warnx("Unable to set LDAP_OPT_X_TLS_HARD to %d: %d: %s", arg, err, ldap_err2string(err));
		return (false);
	}
	return (true);
}

- (BOOL) setTLSCACertFile: (LFString *) fileName {
	if ([self _setLDAPOption: LDAP_OPT_X_TLS_CACERTFILE value: [fileName cString] connection: ldapConn])
		if ([self _setTLSRequireCert])
			return true;
	return false;
}

- (BOOL) setTLSCACertDir: (LFString *) directory {
	if ([self _setLDAPOption: LDAP_OPT_X_TLS_CACERTDIR value: [directory cString] connection: ldapConn])
		if ([self _setTLSRequireCert])
			return true;
	return false;
}

- (BOOL) setTLSClientCert: (LFString *) certFile keyFile: (LFString *) keyFile {
	if ([self _setLDAPOption: LDAP_OPT_X_TLS_CERTFILE value: [certFile cString] connection: ldapConn])
		if ([self _setLDAPOption: LDAP_OPT_X_TLS_KEYFILE value: [keyFile cString] connection: ldapConn])
			return true;
	return false;
}

- (BOOL) setTLSCipherSuite: (LFString *) cipherSuite {
	return [self _setLDAPOption: LDAP_OPT_X_TLS_CIPHER_SUITE value: [cipherSuite cString] connection: ldapConn];
}

@end
