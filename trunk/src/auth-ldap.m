/*
 * auth_ldap.m
 * OpenVPN LDAP Authentication Plugin
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

#include <err.h>
#include <stdio.h>
#include <stdlib.h>
#include <ldap.h>

#include <openvpn-plugin.h>

#include <LFString.h>
#include <LFAuthLDAPConfig.h>
#include <TRLDAPEntry.h>
#include <TRLDAPGroupConfig.h>
#include <LFLDAPConnection.h>

/* Plugin Context */
typedef struct ldap_ctx {
	LFAuthLDAPConfig *config;
} ldap_ctx;


/* Safe Malloc */
void *xmalloc(size_t size) {
	void *ptr;
	ptr = malloc(size);
	if (!ptr)
		err(1, "malloc returned NULL");

	return (ptr);
}

void *xrealloc(void *oldptr, size_t size) {
	void *ptr;
	ptr = realloc(oldptr, size);
	if (!ptr)
		err(1, "realloc returned NULL");

	oldptr = ptr;

	return (ptr);
}

char *xstrdup(const char *str) {
	void *ptr;
	ptr = strdup(str);
	if (!ptr)
		err(1, "strdup returned NULL");

	return (ptr);
}

static const char *get_env(const char *key, const char *env[]) {
	int i;
		
	if (!env)
		return (NULL);

	for (i = 0; env[i]; i++) {
		int keylen = strlen(key);

		if (keylen > strlen(env[i]))
			continue;

		if (!strncmp(key, env[i], keylen)) {
			const char *p = env[i] + keylen;
			if (*p == '=')
				return (p + 1);
		}
	}

	return (NULL);
}

static LFString *quoteForSearch(const char *string)
{
	const char specialChars[] = "*()\\"; /* RFC 2254. We don't care about NULL */
	LFString *result = [[LFString alloc] init];
	LFString *unquotedString, *part;

	/* Make a copy of the string */
	unquotedString = [[LFString alloc] initWithCString: string];

	/* Initialize the result */
	result = [[LFString alloc] init];

	/* Quote all occurrences of the special characters */
	while ((part = [unquotedString substringToCharset: specialChars]) != NULL) {
		LFString *temp;
		int index;
		char c;

		/* Append everything until the first special character */
		[result appendString: part];

		/* Append the backquote */
		[result appendCString: "\\"];

		/* Get the special character */
		index = [unquotedString indexToCharset: specialChars];
		temp = [unquotedString substringFromIndex: index];
		c = [temp charAtIndex: 0];
		[temp release];

		/* Append it, too! */
		[result appendChar: c];

		/* Move unquotedString past the special character */
		temp = [unquotedString substringFromCharset: specialChars];

		[unquotedString release];
		unquotedString = temp;
	}

	/* Append the remainder, if any */
	if (unquotedString) {
		[result appendString: unquotedString];
		[unquotedString release];
	}

	return (result);
}

static LFString *createSearchFilter(LFString *template, const char *username) {
	LFString *templateString;
	LFString *result, *part;
	LFString *quotedName;
	const char userFormat[] = "%u";

	/* Copy the template */
	templateString = [[LFString alloc] initWithString: template];

	/* Initialize the result */
	result = [[LFString alloc] init];

	/* Quote the username */
	quotedName = quoteForSearch(username);

	while ((part = [templateString substringToCString: userFormat]) != NULL) {
		LFString *temp;

		/* Append everything until the first %u */
		[result appendString: part];
		[part release];

		/* Append the username */
		[result appendString: quotedName];

		/* Move templateString past the %u */
		temp = [templateString substringFromCString: userFormat];
		[templateString release];
		templateString = temp;
	}

	[quotedName release];

	/* Append the remainder, if any */
	if (templateString) {
		[result appendString: templateString];
		[templateString release];
	}

	return (result);
}

OPENVPN_EXPORT openvpn_plugin_handle_t
openvpn_plugin_open_v1(unsigned int *type, const char *argv[], const char *envp[]) {
	ldap_ctx *ctx = xmalloc(sizeof(ldap_ctx));


	ctx->config = [[LFAuthLDAPConfig alloc] initWithConfigFile: argv[1]];
	if (!ctx->config) {
		return (NULL);
	}

	*type = OPENVPN_PLUGIN_MASK(OPENVPN_PLUGIN_AUTH_USER_PASS_VERIFY);

	return (ctx);
}

OPENVPN_EXPORT void
openvpn_plugin_close_v1(openvpn_plugin_handle_t handle)
{
	ldap_ctx *ctx = handle;
	[ctx->config release];
	free(ctx);
}

LFLDAPConnection *connect_ldap(LFAuthLDAPConfig *config) {
	LFLDAPConnection *ldap;
	LFString *value;

	/* Initialize our LDAP Connection */
	ldap = [[LFLDAPConnection alloc] initWithURL: [config url] timeout: [config timeout]];
	if (!ldap)
		return nil;

        /* Certificate file */
	if ((value = [config tlsCACertFile])) 
		if (![ldap setTLSCACertFile: value])
			goto error;

	/* Certificate directory */
	if ((value = [config tlsCACertDir])) 
		if (![ldap setTLSCACertDir: value])
			goto error;

	/* Client Certificate Pair */
	if ([config tlsCertFile] && [config tlsKeyFile])
		if(![ldap setTLSClientCert: [config tlsCertFile] keyFile: [config tlsKeyFile]])
			goto error;

	/* Cipher suite */
	if ((value = [config tlsCipherSuite]))
		if(![ldap setTLSCipherSuite: value])
			goto error;

	/* Start TLS */
	if ([config tlsEnabled])
		if (![ldap startTLS])
			goto error;

	return ldap;

error:
	[ldap release];
	return nil;
}

static TRLDAPEntry *auth_ldap_user(LFLDAPConnection *ldap, LFAuthLDAPConfig *config, const char *username, const char *password) {
	LFLDAPConnection	*authConn;
	TREnumerator		*entryIter;
	TRArray			*ldapEntries;
	TRLDAPEntry		*result = nil;
	LFString		*searchFilter;
	TRLDAPEntry		*entry;

	/* Assemble our search filter */
	searchFilter = createSearchFilter([config searchFilter], username);

	/* Search! */
	ldapEntries = [ldap searchWithFilter: searchFilter
		scope: LDAP_SCOPE_SUBTREE
		baseDN: [config baseDN]
		attributes: NULL];
	[searchFilter release];
	if (!ldapEntries)
		return nil;
		
	/* Create a second connection for binding */
	authConn = connect_ldap(config);
	if (!authConn) {
		[ldapEntries release];
		return nil;
	}

	/* The specified search string may return more than one entry.
	 * We'll acquiesce to the operator's potentially disastrous demands,
	 * and try to bind with all of them. */
	entryIter = [ldapEntries objectEnumerator];
	while ((entry = [entryIter nextObject]) != nil) {
		LFString *passwordString;

		/* Allocate the string to pass to bindWithDN */
		passwordString = [[LFString alloc] initWithCString: password];

		if ([authConn bindWithDN: [entry dn] password: passwordString]) {
			[passwordString release];
			result = [entry retain];
			break;
		}
		[passwordString release];
	}

	[authConn release];
	[ldapEntries release];
	[entryIter release];

	return result;
}

static TRLDAPGroupConfig *validate_ldap_groups(LFLDAPConnection *ldap, LFAuthLDAPConfig *config, TRLDAPEntry *ldapUser) {
	TREnumerator *groupIter;
	TRLDAPGroupConfig *groupConfig;
	TRArray *ldapEntries;
	TREnumerator *entryIter;
	TRLDAPEntry *entry;
	TRLDAPGroupConfig *result = nil;


	/*
	 * Groups are loaded into the array in the order that they are listed
	 * in the configuration file, and we are expected to perform
	 * "first match". Thusly, we'll walk the stack from the bottom up.
	 */
	groupIter = [[config ldapGroups] objectReverseEnumerator];
	while ((groupConfig = [groupIter nextObject]) != nil) {
		/* Search for the group */
		ldapEntries = [ldap searchWithFilter: [groupConfig searchFilter]
			scope: LDAP_SCOPE_SUBTREE
			baseDN: [groupConfig baseDN]
			attributes: NULL];

		/* Error occured, all stop */
		if (!ldapEntries)
			break;

		/* Iterate over the returned entries */
		entryIter = [ldapEntries objectEnumerator];
		while ((entry = [entryIter nextObject]) != nil) {
			if ([ldap compareDN: [entry dn] withAttribute: [groupConfig memberAttribute] value: [ldapUser dn]]) {
				/* Group match! */
				result = groupConfig;
			}
		}
		[entryIter release];
		[ldapEntries release];
		if (result)
			break;
	}

	[groupIter release];
	return result;
}

OPENVPN_EXPORT int
openvpn_plugin_func_v1(openvpn_plugin_handle_t handle, const int type, const char *argv[], const char *envp[]) {
	const char *username = get_env("username", envp);
	const char *password = get_env("password", envp);
	ldap_ctx *ctx = handle;
	LFLDAPConnection *ldap;
	TRLDAPEntry *ldapUser;
	TRLDAPGroupConfig *groupConfig;
	int ret = OPENVPN_PLUGIN_FUNC_ERROR;

	if (type != OPENVPN_PLUGIN_AUTH_USER_PASS_VERIFY)
		return (OPENVPN_PLUGIN_FUNC_ERROR);

	if (!username || !password)
		return (OPENVPN_PLUGIN_FUNC_ERROR);


	/* Create an LDAP connection */
	if (!(ldap = connect_ldap(ctx->config))) {
		return (OPENVPN_PLUGIN_FUNC_ERROR);
	}

	/* Search and bind */
	ldapUser = auth_ldap_user(ldap, ctx->config, username, password);
	if (!ldapUser) {
		/* No such user or authentication failure */
		ret = OPENVPN_PLUGIN_FUNC_ERROR;
	} else {
		/* User authenticated */
		/* Match up groups, if any */
		if ([ctx->config ldapGroups]) {
			groupConfig = validate_ldap_groups(ldap, ctx->config, ldapUser);
			if (!groupConfig && [ctx->config requireGroup]) {
				/* No group match, and group membership is required */
				ret = OPENVPN_PLUGIN_FUNC_ERROR;
			} else {
				/* Group match! */
				ret = OPENVPN_PLUGIN_FUNC_SUCCESS;
			}
		} else {
			// No groups, user OK
			ret = OPENVPN_PLUGIN_FUNC_SUCCESS;
		}
	}

	[ldapUser release];
	[ldap release];
	return (ret);
}
