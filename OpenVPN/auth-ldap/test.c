/*
 * test.c
 * OpenVPN LDAP Authentication Plugin Test Harness
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

#include <openvpn-plugin.h>

int main(int argc, const char *argv[]) {
	openvpn_plugin_handle_t handle;
	unsigned int type;
	int err;

	const char *envp[] = {
		"username=vpn@arctic.threerings.net",
		"password=c50fefa34ca6f51a5b90c74d5d86f827",
		NULL
	};
	const char *argp[] = {
		"plugin.so",
		"auth-ldap.conf",
		"uid=%u,ou=People,dc=earth,dc=threerings,dc=net",
		"uid=%u,ou=Service Accounts,dc=earth,dc=threerings,dc=net",
		NULL
	};

	handle = openvpn_plugin_open_v1(&type, argp, envp);

	if (!handle)
		errx(1, "Initialization Failed!\n");

	err = openvpn_plugin_func_v1(handle, OPENVPN_PLUGIN_AUTH_USER_PASS_VERIFY, argp, envp);
	if (err != OPENVPN_PLUGIN_FUNC_SUCCESS) {
		printf("Authorization Failed!\n");
	} else {
		printf("Authorization Succeed!\n");
	}

	openvpn_plugin_close_v1(handle);

	exit (0);
}
