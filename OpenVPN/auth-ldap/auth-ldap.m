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
#include <LFLDAPConnection.h>

/* Plugin Context */
struct ldap_ctx {
	LFAuthLDAPConfig *config;
	LFLDAPConnection *ldap;
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


static LFString *rfc2253_quote(const char *name)
{
	const char specialChars[] = " \t\"#+,;<>\\";
	LFString *result = [[LFString alloc] init];
	LFString *unquotedName, *part;

	/* Convert to a LFString */
	unquotedName = [[LFString alloc] initWithCString: name];

	/* Initialize the result */
	result = [[LFString alloc] init];

	/*
	 * RFC 2253 only requires that we quote leading or trailing
	 * white space, and leading '#' characters. For simplicity's 
	 * sake, we quote all occurrences of the special characters.
	 */
	
	while ((part = [unquotedName substringToCharset: specialChars]) != NULL) {
		LFString *temp;
		int index;
		char c;

		/* Append everything until the first special character */
		[result appendString: part];

		/* Append the backquote */
		[result appendCString: "\\"];

		/* Get the special character */
		index = [unquotedName indexToCharset: specialChars];
		temp = [unquotedName substringFromIndex: index];
		c = [temp charAtIndex: 0];
		[temp dealloc];

		/* Append it, too! */
		[result appendChar: c];

		/* Move unquotedName past the special character */
		temp = [unquotedName substringFromCharset: specialChars];

		[unquotedName dealloc];
		unquotedName = temp;
	}

	/* Append the remainder, if any */
	if (unquotedName) {
		[result appendString: unquotedName];
		[unquotedName dealloc];
	}

	return (result);
}

static LFString *mapUserToDN(const char *template, const char *username) {
	LFString *templateString;
	LFString *result, *part;
	LFString *quotedName;
	const char userFormat[] = "%u";

	/* Convert to a LFString */
	templateString = [[LFString alloc] initWithCString: template];

	/* Initialize the result */
	result = [[LFString alloc] init];

	/* Quote the username */
	quotedName = rfc2253_quote(username);

	while ((part = [templateString substringToCString: userFormat]) != NULL) {
		LFString *temp;

		/* Append everything until the first %u */
		[result appendString: part];

		/* Append the username */
		[result appendString: quotedName];

		/* Move templateString past the %u */
		temp = [templateString substringFromCString: userFormat];
		[templateString dealloc];
		templateString = temp;
	}

	[quotedName dealloc];

	/* Append the remainder, if any */
	if (templateString) {
		[result appendString: templateString];
		[templateString dealloc];
	}

	return (result);
}

OPENVPN_EXPORT openvpn_plugin_handle_t
openvpn_plugin_open_v1(unsigned int *type, const char *argv[], const char *envp[]) {
	ldap_ctx *ctx = xmalloc(sizeof(ldap_ctx));

	ctx->config = [[LFAuthLDAPConfig alloc] initWithConfigFile: argv[1]];
	ctx->ldap = [[LFLDAPConnection alloc] initWithConfig: ctx->config];
	if (!ctx->config)
		return (NULL);

	*type = OPENVPN_PLUGIN_MASK(OPENVPN_PLUGIN_AUTH_USER_PASS_VERIFY);

	return (ctx);
}

OPENVPN_EXPORT void
openvpn_plugin_close_v1(openvpn_plugin_handle_t handle)
{
	ldap_ctx *ctx = handle;
	[ctx->ldap dealloc]; /* deallocs our config, too */
	free (handle);
}

OPENVPN_EXPORT int
openvpn_plugin_func_v1(openvpn_plugin_handle_t handle, const int type, const char *argv[], const char *envp[]) {
	const char *username = get_env("username", envp);
	const char *password = get_env("password", envp);
	ldap_ctx *ctx = handle;
	LFString *dn;
	int i;

	if (!username || !password)
		return (OPENVPN_PLUGIN_FUNC_ERROR);

	/* DN templates start at argv[2] */
	for (i = 2; argv[i]; i++) {
		dn = mapUserToDN(argv[i], username);
		if (!dn) {
			fprintf(stderr, "Invalid DN template: %s\n", argv[i]);
			[dn dealloc];
			continue;
		}
		if ([ctx->ldap bindWithDN: [dn cString] password: password]) {
			[dn dealloc];
			[ctx->ldap unbind];
			return (OPENVPN_PLUGIN_FUNC_SUCCESS);
		}
		[dn dealloc];
	}

	return (OPENVPN_PLUGIN_FUNC_ERROR);
}
