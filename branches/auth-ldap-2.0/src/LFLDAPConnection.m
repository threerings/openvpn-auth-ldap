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
#include <sys/time.h>

#include "LFLDAPConnection.h"
#include "TRLog.h"

#include "auth-ldap.h"

static int ldap_get_errno(LDAP *ld) {
	int err;
	if (ldap_get_option(ld, LDAP_OPT_ERROR_NUMBER, &err) != LDAP_OPT_SUCCESS)
		err = LDAP_OTHER;
	return err;
}

/*
 * Private Methods
 */
@interface LFLDAPConnection (Private)
- (void) log: (loglevel_t) level withLDAPError: (int) error message: (char *) message;
@end

@implementation LFLDAPConnection (Private)

/*!
 * Log an LDAP error, including the LDAP_OPT_ERROR_STRING, if available.
 */
- (void) log: (loglevel_t) level withLDAPError: (int) error message: (char *) message {

	char *ld_error = NULL;
	ldap_get_option(ldapConn, LDAP_OPT_ERROR_STRING, &ld_error);
	if (ld_error && strlen(ld_error) != 0) {
		[TRLog log: level withMessage: "%s: %s (%s)", message, ldap_err2string(error), ld_error];
	} else {
		[TRLog log: level withMessage: "%s: %s", message, ldap_err2string(error)];
	}

	if (ld_error) {
		ldap_memfree(ld_error);
	}

}

@end

/*
 * Public Methods
 */
@implementation LFLDAPConnection

- (id) initWithURL: (LFString *) url timeout: (int) timeout {
	struct timeval ldapTimeout;
	int arg;

	self = [self init];
	if (!self)
		return NULL;

	ldap_initialize(&ldapConn, [url cString]);

	if (!ldapConn) {
		[TRLog error: "Unable to initialize LDAP server %s", [url cString]];
		[self release];
		return (NULL);
	}

	_timeout = timeout;

	ldapTimeout.tv_sec = _timeout;
	ldapTimeout.tv_usec = 0;

	if (ldap_set_option(ldapConn, LDAP_OPT_NETWORK_TIMEOUT, &ldapTimeout) != LDAP_OPT_SUCCESS)
		[TRLog warning: "Unable to set LDAP network timeout."];

	arg = LDAP_VERSION3;
	if (ldap_set_option(ldapConn, LDAP_OPT_PROTOCOL_VERSION, &arg) != LDAP_OPT_SUCCESS) {
		[TRLog error: "Unable to enable LDAP v3 Protocol."];
		[self release];
		return (NULL);
	}

	return (self);
}

- (void) dealloc {
	int err;
	err = ldap_unbind_ext_s(ldapConn, NULL, NULL);
	if (err != LDAP_SUCCESS) {
		[self log: TRLOG_WARNING withLDAPError: err message: "Unable to unbind from LDAP server"];
	}
	[super dealloc];
}

/*!
 * Start TLS on the LDAP connection.
 */
- (BOOL) startTLS {
	int err;
	err = ldap_start_tls_s(ldapConn, NULL, NULL);
	if (err != LDAP_SUCCESS) {
		[self log: TRLOG_ERR withLDAPError: err message: "Unable to enable STARTTLS"];
		return (NO);
	}

	return (YES);
}

- (BOOL) bindWithDN: (LFString *) bindDN password: (LFString *) password {
	int msgid, err;
	LDAPMessage *res;
	struct berval cred;
	struct berval *servercred = NULL;
	struct timeval timeout;

	/* Set up berval structure for our credentials */
	cred.bv_val = (char *) [password cString];
	cred.bv_len = [password length] - 1; /* Length includes NULL terminator */

	/*
	 * By default, some LDAP servers, in accordance with the RFC, treat a bind
	 * with a valid DN and an empty (zero length) password as a successful
	 * anonymous bind. There is no way to determine from the bind result
	 * whether the bind was anonymous. Thus, we must forbid zero length
	 * passwords.
	 */
	if (cred.bv_len == 0) {
		[TRLog error: "ldap_bind with zero-length password is forbidden."];
		return (false);
	}

	if ((err = ldap_sasl_bind(ldapConn,
					[bindDN cString],
					LDAP_SASL_SIMPLE,
					&cred,
					NULL,
					NULL,
					&msgid)) != LDAP_SUCCESS) {
		[self log: TRLOG_ERR withLDAPError: err message: "LDAP bind failed immediately"];
		return (false);
	}

	/* Wait for the result */
	timeout.tv_sec = _timeout;
	timeout.tv_usec = 0;
	if (ldap_result(ldapConn, msgid, 1, &timeout, &res) == -1) {
		err = ldap_get_errno(ldapConn);
		if (err == LDAP_TIMEOUT)
			ldap_abandon_ext(ldapConn, msgid, NULL, NULL);
		[self log: TRLOG_ERR withLDAPError: err message: "LDAP bind failed"];
		return (false);
	}

	/* Parse the bind result */
	err = ldap_parse_sasl_bind_result(ldapConn, res, &servercred, 0);
	if (servercred != NULL)
		ber_bvfree(servercred);

	/* Did the parse (not the bind) succeed. Different LDAP
	 * libraries seem to differ on whether this is the parse result,
	 * or the bind result, so we play it safe and pull the bind result */
	if (err != LDAP_SUCCESS) {
		ldap_msgfree(res);
		return false;
	}

	/* Did the the bind succeed? */
	if (ldap_parse_result(ldapConn, res, &err, NULL, NULL, NULL, NULL, 1) != LDAP_SUCCESS) {
		/* Parsing failed */
		return false;
	}

	if (err == LDAP_SUCCESS) {
		/* Bind succeeded */
		return (true);
	}

	[self log: TRLOG_ERR withLDAPError: err message: "LDAP bind failed"];
	return (false);
}

/*!
 * Run an LDAP search.
 * @param filter: LDAP search filter.
 * @param scope: LDAP scope (LDAP_SCOPE_BASE, LDAP_SCOPE_ONE, or LDAP_SCOPE_SUBTREE)
 * @param base: LDAP search base DN.
 * @param attributes: Attributes to return. If nil, returns all attributes.
 * @return: An array of TRLDAPEntry instances.
 */
- (TRArray *)
	searchWithFilter: (LFString *) filter
	scope: (int) scope
	baseDN: (LFString *) base
	attributes: (TRArray *) attributes
{
	TREnumerator *iter;
	LDAPMessage *res;
	LDAPMessage *entry;
	char *attr;
	struct berval **vals;

	TRArray *entries;

	struct timeval timeout;

	char **attrArray;
	LFString *attrString;

	int count;
	int numEntries;
	int err;


	count = 0;
	entries = nil;

	/* Build the attrArray */
	if (attributes) {
		attrArray = xmalloc(sizeof(char *) * [attributes count]);
		iter = [attributes objectEnumerator];
		while ((attrString = [iter nextObject]) != nil) {
			attrArray[count] = (char *) [attrString cString];
			count++;
		}
	} else {
		/* Return all attributes */
		attrArray = NULL;
	}

	/* Set up the timeout */
	timeout.tv_sec = _timeout;
	timeout.tv_usec = 0;

	/* MISSING:
	 * Support for user-specified 'attrOnly' mode.
	 * Non-hardcoded size limit.
	 */
	if ((err = ldap_search_ext_s(ldapConn, [base cString], scope, [filter cString], attrArray, 0, NULL, NULL, &timeout, 1024, &res)) != LDAP_SUCCESS) {
		[self log: TRLOG_ERR withLDAPError: err message: "LDAP search failed"];
		goto finish;
	}

	/* Get the number of returned entries */
	if ((numEntries = ldap_count_entries(ldapConn, res)) == -1) {
		[TRLog debug: "ldap_count_entries failed: %d: %s", numEntries, ldap_err2string(numEntries)];
		goto finish;
	}

	/* If 0, return nil */
	if (numEntries == 0) {
		ldap_msgfree(res);
		goto finish;
	}

	/* Allocate an array to hold entries */
	entries = [[TRArray alloc] init];
	/* Grab attributes and values for each entry */
	for (entry = ldap_first_entry(ldapConn, res); entry != NULL; entry = ldap_next_entry(ldapConn, entry)) {
		TRLDAPEntry *ldapEntry;
		TRHash *ldapAttributes;
		BerElement *ptr;
		int maxCapacity = 2048;
		LFString *dn;
		char *dnCString;

		ldapAttributes = [[TRHash alloc] initWithCapacity: maxCapacity];

		/* Grab our entry's DN */
		dnCString = ldap_get_dn(ldapConn, entry);
		dn = [[LFString alloc] initWithCString: dnCString];
		ldap_memfree(dnCString);
		
		/* Load all attributes and associated values */
		for (attr = ldap_first_attribute(ldapConn, entry, &ptr); attr != NULL; attr = ldap_next_attribute(ldapConn, entry, ptr)) {
			LFString *attrName;
			LFString *valueString;
			TRArray *attrValues;
			int i;

			/* Don't exceed the maximum capacity of the hash table */
			if(--maxCapacity == 0)
				break;

			attrName = [[LFString alloc] initWithCString: attr];
			attrValues = [[TRArray alloc] init];

			vals = ldap_get_values_len(ldapConn, entry, attr);
			if (vals) {
				for (i = 0; vals[i] != NULL; i++) {
					/* XXX: This could be binary. This is not the end of the world, but a braindead
					 * client of this API could do something dumb. There doesn't seem to be any sane
					 * way to determine whether data is binary or non-binary. At the very least, we
					 * enforce NULL termination by turning the data into a string. */
					valueString = [[LFString alloc] initWithBytes: vals[i]->bv_val numBytes: vals[i]->bv_len];
					/* Pass our value string to the attrValues array */
					[attrValues addObject: valueString];
					[valueString release];
				}
				ldap_value_free_len(vals);
			}

			/* Pass our attribute string and array of values to the
			 * entryAttributes hash table */
			[ldapAttributes setObject: attrValues forKey: attrName];
			[attrName release];
			[attrValues release];
			ldap_memfree(attr);
		}

		/* Free ber ptr */
		ber_free(ptr, 0);

		/* Instantiate our entry */
		ldapEntry = [[TRLDAPEntry alloc] initWithDN: dn attributes: ldapAttributes];
		[dn release];
		[ldapAttributes release];

		/* Pass our entry off to the entries array */
		[entries addObject: ldapEntry];
		[ldapEntry release];
	}

	/* free memory allocated for search results */
	ldap_msgfree(res);

finish:
	if (attrArray)
		free(attrArray);
	return entries;
}

- (BOOL) compareDN: (LFString *) dn withAttribute: (LFString *) attribute value: (LFString *) value {
	struct timeval	timeout;
	LDAPMessage	*res;
	struct berval	bval;
	int		err;
	int		msgid;

	/* Set up the ber structure for our value */
	bval.bv_val = (char *) [value cString];
	bval.bv_len = [value length] - 1; /* Length includes NULL terminator */

	/* Set up the timeout */
	timeout.tv_sec = _timeout;
	timeout.tv_usec = 0;

	/* Perform the compare */
	if ((err = ldap_compare_ext(ldapConn, [dn cString], [attribute cString], &bval, NULL, NULL, &msgid)) != LDAP_SUCCESS) {
		[TRLog debug: "LDAP compare failed: %d: %s", err, ldap_err2string(err)];
		return NO;
	}

	/* Wait for the result */
	if (ldap_result(ldapConn, msgid, 1, &timeout, &res) == -1) {
		err = ldap_get_errno(ldapConn);
		if (err == LDAP_TIMEOUT)
			ldap_abandon_ext(ldapConn, msgid, NULL, NULL);

		[TRLog debug: "ldap_compare_ext failed: %s", ldap_err2string(err)];
		return NO;
	}

	/* Check the result */
	if (ldap_parse_result(ldapConn, res, &err, NULL, NULL, NULL, NULL, 1) != LDAP_SUCCESS) {
		/* Parsing failed */
		return NO;
	}
	if (err == LDAP_COMPARE_TRUE)
		return YES;
	else
		return NO;

	return NO;
}


- (BOOL) _setLDAPOption: (int) opt value: (const char *) value connection: (LDAP *) ldapConn {
	int err;
	if ((err = ldap_set_option(NULL, opt, (const void *) value)) != LDAP_SUCCESS) {
		[TRLog debug: "Unable to set ldap option %d to %s: %d: %s", opt, value == NULL ? "False" : value, err, ldap_err2string(err)];
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
		[TRLog debug: "Unable to set LDAP_OPT_X_TLS_HARD to %d: %d: %s", arg, err, ldap_err2string(err)];
		return (false);
	}
	return (true);
}

- (BOOL) setReferralEnabled: (BOOL) enabled {
	if (enabled)
		return [self _setLDAPOption: LDAP_OPT_REFERRALS value: LDAP_OPT_OFF connection: ldapConn];
	else
		return [self _setLDAPOption: LDAP_OPT_REFERRALS value: LDAP_OPT_OFF connection: ldapConn];
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
