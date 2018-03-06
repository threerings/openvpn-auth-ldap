/*
 * testplugin.c vi:ts=4:sw=4:expandtab:
 * OpenVPN LDAP Authentication Plugin Test Driver
 *
 * Copyright (c) 2005 - 2007 Landon Fuller <landonf@threerings.net>
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
#include <errno.h>

#include <openvpn-plugin.h>

/* Argument / environment templates */
const char username_template[] = "username=";
const char password_template[] = "password=";
const char conf_template[] = "/tmp/openvpn-auth-ldap-test.XXXXXXXXXXXXX";

/* Configuration data */
typedef struct {
    /* User name and password environmental variables */
    char *username;
    char *password;

    /* Path to config file */
    const char *config_file;

    /* OpenVPN per client context */
    void *pcc;

    /* OpenVPN plugin environment */
    const char **envp;

    /* OpenVPN plugin open/close arguments */
    const char **argp;

    /* OpenVPN 'command line' script arguments */
    const char **argp_script;

    /* OpenVPN Plugin value strings and structured data return */
    struct openvpn_plugin_string_list **return_list;
} plugin_data;

/**
 * Initialize the plugin data structure. This function is not thread-safe; it
 * interacts with the user on stdin, and calls other non-reentrant functions (eg getpass()).
 */
static plugin_data *plugin_data_init (const char *config_file) {
    plugin_data *data;
    char username[128];
    char *password;

    /* Alloc and zero-initialize a new data structure */
    data = calloc(1, sizeof(plugin_data));

    /* Fetch the username and password */
    printf("Username: ");
    if (fgets(username, sizeof(username), stdin) == NULL) {
        errx(1, "Failed to read username");
    }

    password = getpass("Password: ");
    
    /* Strip off the trailing \n */
    username[strlen(username) - 1] = '\0';

    /* Assemble the username env variable */
    data->username = malloc(sizeof(username_template) + strlen(username));
    strcpy(data->username, username_template);
    strcat(data->username, username);

    /* Assemble the password env variable */
    data->password = malloc(sizeof(password_template) + strlen(password));
    strcpy(data->password, password_template);
    strcat(data->password, password);

    /* Set up the plugin environment array -- username, password, ifconfig_pool_remote_ip, NULL */
    data->envp = calloc(4, sizeof(char *));
    data->envp[0] = data->username;
    data->envp[1] = data->password;
    data->envp[2] = "ifconfig_pool_remote_ip=10.0.50.1";
    data->envp[3] = NULL;

    /* Set up the plugin argument array -- plugin path, config file, NULL */
    data->argp = calloc(3, sizeof(char *));
    data->argp[0] = "plugin.so";
    data->argp[1] = config_file;
    data->argp[2] = NULL;

    /* Set up the plugin "script" argument array -- plugin path, dynamic config file, NULL */
    // TODO: wire up dynamic config file support.
    data->argp_script = calloc(3, sizeof(char *));
    data->argp_script[0] = "plugin.so";
    data->argp_script[1] = NULL;
    data->argp_script[2] = NULL;

    /* Set up the plugin "per_client_context" argument -- NULL */
    data->pcc = malloc(sizeof(void *));
    data->pcc = NULL;

    /* Set up the plugin string list return -- NULL */
    data->return_list = malloc(sizeof(struct openvpn_plugin_string_list **));

    return data;
}

static void plugin_data_free (plugin_data *data) {
    if (data->username)
        free(data->username);

    if (data->password)
        free(data->password);

    if (data->envp)
        free(data->envp);

    if (data->argp)
        free(data->argp);

    if (data->argp_script)
        free(data->argp_script);

    free(data);
}

int main(int argc, const char *argv[]) {
    openvpn_plugin_handle_t handle;
    plugin_data *data;
    const char *config_file;
    unsigned int plugin_type;
    int retval = 1;
    int err;

    if (argc != 2) {
        errx(1, "Usage: %s <config file>", argv[0]);
    } else {
        config_file = argv[1];
    }

    /* Configure the plugin environment */
    data = plugin_data_init(config_file);

    handle = openvpn_plugin_open_v2(&plugin_type, data->argp, data->envp, data->return_list);

    if (!handle) {
        printf("Initialization Failed!\n");
        goto cleanup;
    }

    /* Authenticate */
    err = openvpn_plugin_func_v2(handle, OPENVPN_PLUGIN_AUTH_USER_PASS_VERIFY, data->argp_script, data->envp, data->pcc, data->return_list);
    if (err != OPENVPN_PLUGIN_FUNC_SUCCESS) {
        printf("Authorization Failed!\n");
        goto cleanup;
    } else {
        printf("Authorization Succeed!\n");
    }

    /* Client Connect */
    err = openvpn_plugin_func_v2(handle, OPENVPN_PLUGIN_CLIENT_CONNECT, data->argp_script, data->envp, data->pcc, data->return_list);
    if (err != OPENVPN_PLUGIN_FUNC_SUCCESS) {
        printf("client-connect failed!\n");
        goto cleanup;
    } else {
        printf("client-connect succeed!\n");
    }

    /* Client Disconnect */
    err = openvpn_plugin_func_v2(handle, OPENVPN_PLUGIN_CLIENT_DISCONNECT, data->argp, data->envp, data->pcc, data->return_list);
    if (err != OPENVPN_PLUGIN_FUNC_SUCCESS) {
        printf("client-disconnect failed!\n");
        goto cleanup;
    } else {
        printf("client-disconnect succeed!\n");
    }

    /* Everything worked. Set our return value accordingly. */
    retval = 0;

cleanup:
    openvpn_plugin_close_v1(handle);
    plugin_data_free(data);

    exit(retval);
}
