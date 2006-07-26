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
#include <LFLDAPConnection.h>

/* Plugin Context */
struct ldap_ctx {
	LFAuthLDAPConfig *config;
} typedef ldap_ctx;


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

static int authLdap(LFLDAPConnection *ldap, LFAuthLDAPConfig *config, const char *username, const char *password) {
	LFString *searchFilter;
	int ret = OPENVPN_PLUGIN_FUNC_ERROR;
	TRArray *ldapEntries = nil;
	TRLDAPEntry *entry;
	TREnumerator *entryIter;
	// TREnumerator *attrIter, *valueIter,
	// LFString *attr, *value;

	/* Assemble our search filter */
	searchFilter = createSearchFilter([config searchFilter], username);

	/* Search! */
	ldapEntries = [ldap searchWithFilter: searchFilter
		scope: LDAP_SCOPE_SUBTREE
		baseDN: [config baseDN]
		attributes: NULL];
	[searchFilter release];

	/* The specified search string may return more than one entry.
	 * We'll acquiesce to the operator's potentially disastrous demands,
	 * and try to bind with all of them. */
	entryIter = [ldapEntries objectEnumerator];
	while ((entry = [entryIter nextObject]) != nil) {
		LFString *passwordString = [[LFString alloc] initWithCString: password];
		printf("Binding: %s\n", [[entry dn] cString]);
		if ([ldap bindWithDN: [entry dn] password: passwordString]) {
			[passwordString release];
			printf("Successfully authenticated\n");
			ret = OPENVPN_PLUGIN_FUNC_SUCCESS;
			goto cleanup;
		}
		[passwordString release];
	}

cleanup:
	if (ldapEntries)
		[ldapEntries release];
	[entryIter release];
	return ret;
}

OPENVPN_EXPORT int
openvpn_plugin_func_v1(openvpn_plugin_handle_t handle, const int type, const char *argv[], const char *envp[]) {
	const char *username = get_env("username", envp);
	const char *password = get_env("password", envp);
	ldap_ctx *ctx = handle;
	LFLDAPConnection *ldap;
	BOOL ldapSuccess = YES;
	LFString *value;
	int ret;

	if (type != OPENVPN_PLUGIN_AUTH_USER_PASS_VERIFY)
		return (OPENVPN_PLUGIN_FUNC_ERROR);

	if (!username || !password)
		return (OPENVPN_PLUGIN_FUNC_ERROR);

	/* Initialize our LDAP Connection */
	ldap = [[LFLDAPConnection alloc] initWithURL: [ctx->config url] timeout: [ctx->config timeout]];
        /* Certificate file */
	if ((value = [ctx->config tlsCACertFile])) 
		if (![ldap setTLSCACertFile: value])
			ldapSuccess = NO;

	/* Certificate directory */
	if ((value = [ctx->config tlsCACertDir])) 
		if (![ldap setTLSCACertDir: value])
			ldapSuccess = NO;

	/* Client Certificate Pair */
	if ([ctx->config tlsCertFile] && [ctx->config tlsKeyFile])
		if(![ldap setTLSClientCert: [ctx->config tlsCertFile] keyFile: [ctx->config tlsKeyFile]])
			ldapSuccess = NO;

	/* Cipher suite */
	if ((value = [ctx->config tlsCipherSuite]))
		if(![ldap setTLSCipherSuite: value])
			ldapSuccess = NO;

	/* Start TLS */
	if ([ctx->config tlsEnabled])
		if (![ldap startTLS])
			ldapSuccess = NO;

	/* Did an error occur configuring the LDAP connection? */
	if (!ldapSuccess) {
		ret = OPENVPN_PLUGIN_FUNC_ERROR;
		goto cleanup;
	}

	ret = authLdap(ldap, ctx->config, username, password);

cleanup:

	[ldap release];
	return (ret);
}
