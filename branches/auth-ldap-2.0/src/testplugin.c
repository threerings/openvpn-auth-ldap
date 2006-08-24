/*
 * testplugin.c
 * OpenVPN LDAP Authentication Plugin Test Driver
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
#include <unistd.h>
#include <string.h>

#include <openvpn-plugin.h>

const char username_template[] = "username=";
const char password_template[] = "password=";

int main(int argc, const char *argv[]) {
	openvpn_plugin_handle_t handle;
	const char *config;
	unsigned int type;
	const char *envp[4]; /* username, password, ifconfig_pool_remote_ip, NULL */
	char username[30];
	char *password;
	int err;

	if (argc != 2) {
		errx(1, "Usage: %s <config file>", argv[0]);
	} else {
		config = argv[1];
	}

	const char *argp[] = {
		"plugin.so",
		config,
		NULL
	};

	/* Grab username and password */
	printf("Username: ");
	fgets(username, sizeof(username), stdin);
	/* Strip off the trailing \n */
	username[strlen(username) - 1] = '\0';

	password = getpass("Password: ");

	/* Set up username and password */
	envp[0] = malloc(sizeof(username_template) + strlen(username));
	strcpy((char *) envp[0], username_template);
	strcat((char *) envp[0], username);

	envp[1] = malloc(sizeof(password_template) + strlen(password));
	strcpy((char *) envp[1], password_template);
	strcat((char *) envp[1], password);
	/* Remote Pool IP */
	envp[2] = "ifconfig_pool_remote_ip=10.0.50.1";
	envp[3] = NULL;

	handle = openvpn_plugin_open_v1(&type, argp, envp);

	if (!handle)
		errx(1, "Initialization Failed!\n");

	/* Authenticate */
	err = openvpn_plugin_func_v1(handle, OPENVPN_PLUGIN_AUTH_USER_PASS_VERIFY, argp, envp);
	if (err != OPENVPN_PLUGIN_FUNC_SUCCESS) {
		printf("Authorization Failed!\n");
	} else {
		printf("Authorization Succeed!\n");
	}

	/* Client Connect */
	err = openvpn_plugin_func_v1(handle, OPENVPN_PLUGIN_CLIENT_CONNECT, argp, envp);
	if (err != OPENVPN_PLUGIN_FUNC_SUCCESS) {
		printf("client-connect failed!\n");
	} else {
		printf("client-connect succeed!\n");
	}

	/* Client Disconnect */
	err = openvpn_plugin_func_v1(handle, OPENVPN_PLUGIN_CLIENT_DISCONNECT, argp, envp);
	if (err != OPENVPN_PLUGIN_FUNC_SUCCESS) {
		printf("client-disconnect failed!\n");
	} else {
		printf("client-disconnect succeed!\n");
	}

	openvpn_plugin_close_v1(handle);
	free((char *) envp[0]);
	free((char *) envp[1]);

	exit (0);
}
