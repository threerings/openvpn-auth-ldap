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

static LFString *mapUserToDN(const char *template, const char *username) {
	LFString *templateString;
	LFString *result, *part;
	const char userFormat[] = "%u";

	/* Convert to a LFString */
	templateString = [[LFString alloc] initWithCString: template];

	/* Initialize the result */
	result = [[LFString alloc] init];

	while ((part = [templateString substringToCString: userFormat]) != NULL) {
		LFString *temp;

		/* Append everything until the first %u */
		[result appendString: part];

		/* Append the username */
		[result appendCString: username];

		/* Move templateString past the %u */
		temp = [templateString substringFromCString: userFormat];
		[templateString dealloc];
		templateString = temp;
	}

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
	if (!ctx->config)
		return (NULL);

	*type = OPENVPN_PLUGIN_MASK(OPENVPN_PLUGIN_AUTH_USER_PASS_VERIFY);

	return (ctx);
}

OPENVPN_EXPORT void
openvpn_plugin_close_v1(openvpn_plugin_handle_t handle)
{   
	free (handle);
}

OPENVPN_EXPORT int
openvpn_plugin_func_v1(openvpn_plugin_handle_t handle, const int type, const char *argv[], const char *envp[]) {
	const char *username = get_env("username", envp);
	const char *password = get_env("password", envp);
	int i;

	if (!username || !password)
		return (OPENVPN_PLUGIN_FUNC_ERROR);

	/* DN templates start at argv[2] */
	for (i = 2; argv[i]; i++) {
		LFString *dn;
		dn = mapUserToDN(argv[i], username);
		if (!dn) {
			fprintf(stderr, "Invalid DN template: %s\n", argv[i]);
			[dn dealloc];
			continue;
		}
		[dn dealloc];
	}

	return (OPENVPN_PLUGIN_FUNC_ERROR);
}

int main(int argc, const char *argv[]) {
	openvpn_plugin_handle_t handle;
	const char *envp[] = {
		"username=test",
		"password=test",
		NULL
	};
	const char *argp[] = {
		"plugin.so",
		"auth-ldap.conf",
		"uid=%u,ou=People,dc=earth,dc=threerings,dc=net",
		"uid=%u,ou=Service Accounts,dc=earth,dc=threerings,dc=net",
		NULL
	};
	unsigned int type;
	int ret;

	handle = openvpn_plugin_open_v1(&type, argp, envp);

	if (!handle)
		errx(1, "Initialization Failed!\n");

	ret = openvpn_plugin_func_v1(handle, 1, argp, envp);
	if (ret != OPENVPN_PLUGIN_FUNC_SUCCESS) {
		printf("Authorization Failed!\n");
	} else {
		printf("Authorization Succeed!\n");
	}

	openvpn_plugin_close_v1(handle);

	exit (0);
}
