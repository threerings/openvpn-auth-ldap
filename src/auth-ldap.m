/*
 * auth_ldap.m vi:ts=4:sw=4:expandtab:
 * OpenVPN LDAP Authentication Plugin
 *
 * Copyright (c) 2005 - 2007 Landon Fuller <landonf@threerings.net>
 * Copyright (c) 2007 Three Rings Design, Inc.
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
#include <stdarg.h>
#include <errno.h>

#include <ldap.h>

#include <openvpn-plugin.h>

#include <config/TRAuthLDAPConfig.h>
#include <config/TRLDAPGroupConfig.h>

#include <ldap/TRLDAPEntry.h>
#include <ldap/TRLDAPConnection.h>

#include <pf/TRLocalPacketFilter.h>
#include <pf/TRPFAddress.h>

#include <util/TRAutoreleasePool.h>
#include <util/TRString.h>
#include <util/xmalloc.h>

#include <TRLog.h>

/* Plugin Context */
typedef struct ldap_ctx {
    TRAuthLDAPConfig *config;
#ifdef HAVE_PF
    TRLocalPacketFilter *pf;
#endif
} ldap_ctx;


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

static TRString *quoteForSearch(const char *string) {
    const char specialChars[] = "*()\\"; /* RFC 2254. We don't care about NULL */
    TRString *result = [[TRString alloc] init];
    TRString *unquotedString, *part;
    TRAutoreleasePool *pool = [[TRAutoreleasePool alloc] init];

    /* Make a copy of the string */
    unquotedString = [[TRString alloc] initWithCString: string];

    /* Initialize the result */
    result = [[TRString alloc] init];

    /* Quote all occurrences of the special characters */
    while ((part = [unquotedString substringToCharset: specialChars]) != NULL) {
        TRString *temp;
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

        /* Append it, too! */
        [result appendChar: c];

        /* Move unquotedString past the special character */
        temp = [[unquotedString substringFromCharset: specialChars] retain];

        [unquotedString release];
        unquotedString = temp;
    }

    /* Append the remainder, if any */
    if (unquotedString) {
        [result appendString: unquotedString];
        [unquotedString release];
    }

    [pool release];

    return (result);
}

static TRString *createSearchFilter(TRString *template, const char *username) {
    TRString *templateString;
    TRString *result, *part;
    TRString *quotedName;
    const char userFormat[] = "%u";
    TRAutoreleasePool *pool = [[TRAutoreleasePool alloc] init];

    /* Copy the template */
    templateString = [[[TRString alloc] initWithString: template] autorelease];

    /* Initialize the result */
    result = [[TRString alloc] init];

    /* Quote the username */
    quotedName = quoteForSearch(username);

    while ((part = [templateString substringToCString: userFormat]) != NULL) {
        TRString *temp;

        /* Append everything until the first %u */
        [result appendString: part];

        /* Append the username */
        [result appendString: quotedName];

        /* Move templateString past the %u */
        temp = [templateString substringFromCString: userFormat];
        templateString = temp;
    }

    [quotedName release];

    /* Append the remainder, if any */
    if (templateString) {
        [result appendString: templateString];
    }

    [pool release];

    return (result);
}

#ifdef HAVE_PF
static BOOL pf_open(struct ldap_ctx *ctx) {
    TRString *tableName;
    TRLDAPGroupConfig *groupConfig;
    TREnumerator *groupIter;
    pferror_t pferror;

    /* Acquire a reference to /dev/pf */
    ctx->pf = [[TRLocalPacketFilter alloc] init];
    if ((pferror = [ctx->pf open]) != PF_SUCCESS) {
        /* /dev/pf could not be opened. Is it available? */
        [TRLog error: "Failed to open /dev/pf: %s", [TRPacketFilter stringForError: pferror]];
        ctx->pf = nil;
        return NO;
    }

    /* Clear out all referenced PF tables */
    if ((tableName = [ctx->config pfTable])) {
        if ((pferror = [ctx->pf flushTable: tableName]) != PF_SUCCESS) {
            [TRLog error: "Failed to clear packet filter table \"%s\": %s", [tableName cString], [TRPacketFilter stringForError: pferror]];
            goto error;
        }
    }

    if ([ctx->config ldapGroups]) {
        groupIter = [[ctx->config ldapGroups] objectEnumerator];
        while ((groupConfig = [groupIter nextObject]) != nil) {
            if ((tableName = [groupConfig pfTable])) {
                if ((pferror = [ctx->pf flushTable: tableName]) != PF_SUCCESS) {
                    [TRLog error: "Failed to clear packet filter table \"%s\": %s", [tableName cString], [TRPacketFilter stringForError: pferror]];
                    goto error;
                }
            }
        }
    }

    return YES;

    error:
    [ctx->pf release];
    ctx->pf = NULL;
    return NO;
}
#endif /* HAVE_PF */

OPENVPN_EXPORT openvpn_plugin_handle_t
openvpn_plugin_open_v1(unsigned int *type, const char *argv[], const char *envp[]) {
    ldap_ctx *ctx = xmalloc(sizeof(ldap_ctx));

/* Read the configuration */
    ctx->config = [[TRAuthLDAPConfig alloc] initWithConfigFile: argv[1]];
    if (!ctx->config) {
        free(ctx);
        return (NULL);
    }

#ifdef HAVE_PF
    ctx->pf = NULL;
    /* Open reference to /dev/pf and clear out all of our PF tables */
    if ([ctx->config pfEnabled] && !pf_open(ctx)) {
        [ctx->config release];
        free(ctx);
        return (NULL);
    }
#endif


    *type = OPENVPN_PLUGIN_MASK(OPENVPN_PLUGIN_AUTH_USER_PASS_VERIFY) |
        OPENVPN_PLUGIN_MASK(OPENVPN_PLUGIN_CLIENT_CONNECT) |
        OPENVPN_PLUGIN_MASK(OPENVPN_PLUGIN_CLIENT_DISCONNECT);

    return (ctx);
}

OPENVPN_EXPORT void
    openvpn_plugin_close_v1(openvpn_plugin_handle_t handle)
{
    ldap_ctx *ctx = handle;

    /* Clean up the configuration file */
    [ctx->config release];

    /* Clean up PF */
#ifdef HAVE_PF
    if (ctx->pf)
        [ctx->pf release];
#endif

    /* Finished */
    free(ctx);
}

TRLDAPConnection *connect_ldap(TRAuthLDAPConfig *config) {
    TRLDAPConnection *ldap;
    TRString *value;

    /* Initialize our LDAP Connection */
    ldap = [[TRLDAPConnection alloc] initWithURL: [config url] timeout: [config timeout]];
    if (!ldap) {
        [TRLog error: "Unable to open LDAP connection to %s\n", [[config url] cString]];
        return nil;
    }

    /* Referrals */
    if ([config referralEnabled]) {
        if (![ldap setReferralEnabled: YES])
            goto error;
    } else {
        if (![ldap setReferralEnabled: NO])
            goto error;
    }

    /* Bind if requested */
    if ([config bindDN]) {
        if (![ldap bindWithDN: [config bindDN] password: [config bindPassword]]) {
            [TRLog error: "Unable to bind as %s", [[config bindDN] cString]];
            goto error;
        }
    }

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

static TRLDAPEntry *find_ldap_user (TRLDAPConnection *ldap, TRAuthLDAPConfig *config, const char *username) {
    TRString		*searchFilter;
    TRArray			*ldapEntries;
    TRLDAPEntry		*result = nil;

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
    if ([ldapEntries count] < 1) {
        [ldapEntries release];
        return nil;
    }

    /* The specified search string may (but should not) return more than one entry.
     * We ignore any extras. */
    result = [[ldapEntries lastObject] retain];

    return result;
}


static BOOL auth_ldap_user(TRLDAPConnection *ldap, TRAuthLDAPConfig *config, TRLDAPEntry *ldapUser, const char *password) {
    TRLDAPConnection *authConn;
    TRString *passwordString;
    BOOL result = NO;

    /* Create a second connection for binding */
    authConn = connect_ldap(config);
    if (!authConn) {
        return NO;
    }

    /* Allocate the string to pass to bindWithDN */
    passwordString = [[TRString alloc] initWithCString: password];

    if ([authConn bindWithDN: [ldapUser dn] password: passwordString]) {
        result = YES;
    }

    [passwordString release];
    [authConn release];

    return result;
}

static TRLDAPGroupConfig *find_ldap_group(TRLDAPConnection *ldap, TRAuthLDAPConfig *config, TRLDAPEntry *ldapUser) {
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

        if (result)
            break;
    }

    return result;
}

/** Handle user authentication. */
static int handle_auth_user_pass_verify(ldap_ctx *ctx, TRLDAPConnection *ldap, TRLDAPEntry *ldapUser, const char *password) {
    TRLDAPGroupConfig *groupConfig;

    /* Authenticate the user */
    if (!auth_ldap_user(ldap, ctx->config, ldapUser, password)) {
        [TRLog error: "Incorrect password supplied for LDAP DN \"%s\".", [[ldapUser dn] cString]];
        return (OPENVPN_PLUGIN_FUNC_ERROR);
    }

    /* User authenticated, find group, if any */
    if ([ctx->config ldapGroups]) {
        groupConfig = find_ldap_group(ldap, ctx->config, ldapUser);
        if (!groupConfig && [ctx->config requireGroup]) {
            /* No group match, and group membership is required */
            return OPENVPN_PLUGIN_FUNC_ERROR;
        } else {
            /* Group match! */
            return OPENVPN_PLUGIN_FUNC_SUCCESS;
        }
    } else {
        // No groups, user OK
        return OPENVPN_PLUGIN_FUNC_SUCCESS;
    }

    /* Never reached */
    return OPENVPN_PLUGIN_FUNC_ERROR;
}

#ifdef HAVE_PF
/* Add (or remove) the remote address */
static BOOL pf_client_connect_disconnect(struct ldap_ctx *ctx, TRString *tableName, const char *remoteAddress, BOOL connecting) {
    TRString *addressString;
    TRPFAddress *address;
    pferror_t pferror;

    addressString = [[TRString alloc] initWithCString: remoteAddress];
    address = [[TRPFAddress alloc] initWithPresentationAddress: addressString];
    [addressString release];
    if (connecting) {
        [TRLog debug: "Adding address \"%s\" to packet filter table \"%s\".", remoteAddress, [tableName cString]];

        if ((pferror = [ctx->pf addAddress: address toTable: tableName]) != PF_SUCCESS) {
            [TRLog error: "Failed to add address \"%s\" to table \"%s\": %s", remoteAddress, [tableName cString], [TRPacketFilter stringForError: pferror]];
            [address release];
            return NO;
        }
    } else {
        [TRLog debug: "Removing address \"%s\" from packet filter table \"%s\".", remoteAddress, [tableName cString]];
        if ((pferror = [ctx->pf deleteAddress: address fromTable: tableName]) != PF_SUCCESS) {
            [TRLog error: "Failed to remove address \"%s\" from table \"%s\": %s",
                remoteAddress, [tableName cString], [TRPacketFilter stringForError: pferror]];
            [address release];
            return NO;
        }
    }
    [address release];

    return YES;
}
#endif /* HAVE_PF */


/** Handle both connection and disconnection events. */
static int handle_client_connect_disconnect(ldap_ctx *ctx, TRLDAPConnection *ldap, TRLDAPEntry *ldapUser, const char *remoteAddress, BOOL connecting) {
    TRLDAPGroupConfig *groupConfig = nil;
#ifdef HAVE_PF
    TRString *tableName = nil;
#endif

    /* Locate the group (config), if any */
    if ([ctx->config ldapGroups]) {
        groupConfig = find_ldap_group(ldap, ctx->config, ldapUser);
        if (!groupConfig && [ctx->config requireGroup]) {
            [TRLog error: "No matching LDAP group found for user DN \"%s\", and group membership is required.", [[ldapUser dn] cString]];
            /* No group match, and group membership is required */
            return OPENVPN_PLUGIN_FUNC_ERROR;
        }
    }

#ifdef HAVE_PF
    /* Grab the requested PF table name, if any */
    if (groupConfig) {
        tableName = [groupConfig pfTable];
    } else {
        tableName = [ctx->config pfTable];
    }

    if (tableName)
        if (!pf_client_connect_disconnect(ctx, tableName, remoteAddress, connecting))
        return OPENVPN_PLUGIN_FUNC_ERROR;
#endif /* HAVE_PF */

    return OPENVPN_PLUGIN_FUNC_SUCCESS;
}



OPENVPN_EXPORT int
openvpn_plugin_func_v1(openvpn_plugin_handle_t handle, const int type, const char *argv[], const char *envp[]) {
    const char *username, *password, *remoteAddress;
    ldap_ctx *ctx = handle;
    TRLDAPConnection *ldap = nil;
    TRLDAPEntry *ldapUser = nil;
    TRAutoreleasePool *pool = nil;
    int ret = OPENVPN_PLUGIN_FUNC_ERROR;

    /* Per-request allocation pool. */
    pool = [[TRAutoreleasePool alloc] init];

    username = get_env("username", envp);
    password = get_env("password", envp);
    remoteAddress = get_env("ifconfig_pool_remote_ip", envp);

    /* At the very least, we need a username to work with */
    if (!username) {
        [TRLog debug: "No remote username supplied to OpenVPN LDAP Plugin."];
        goto cleanup;
    }

    /* Create an LDAP connection */
    if (!(ldap = connect_ldap(ctx->config))) {
        [TRLog error: "LDAP connect failed."];
        goto cleanup;
    }

    /* Find the user record */
    ldapUser = find_ldap_user(ldap, ctx->config, username);
    if (!ldapUser) {
        /* No such user. */
        [TRLog warning: "LDAP user \"%s\" was not found.", username];
        goto cleanup;
    }

    switch (type) {
        /* Password Authentication */
        case OPENVPN_PLUGIN_AUTH_USER_PASS_VERIFY:
            if (!password) {
                [TRLog debug: "No remote password supplied to OpenVPN LDAP Plugin (OPENVPN_PLUGIN_AUTH_USER_PASS_VERIFY)."];
            } else {
                ret = handle_auth_user_pass_verify(ctx, ldap, ldapUser, password);
            }
            break;
        /* New connection established */
        case OPENVPN_PLUGIN_CLIENT_CONNECT:
            if (!remoteAddress) {
                [TRLog debug: "No remote address supplied to OpenVPN LDAP Plugin (OPENVPN_PLUGIN_CLIENT_CONNECT)."];
            } else {
                ret = handle_client_connect_disconnect(ctx, ldap, ldapUser, remoteAddress, YES);
            }
            break;
        case OPENVPN_PLUGIN_CLIENT_DISCONNECT:
            if (!remoteAddress) {
                [TRLog debug: "No remote address supplied to OpenVPN LDAP Plugin (OPENVPN_PLUGIN_CLIENT_DISCONNECT)."];
            } else {
                ret = handle_client_connect_disconnect(ctx, ldap, ldapUser, remoteAddress, NO);
            }
            break;
        default:
            [TRLog debug: "Unhandled plugin type in OpenVPN LDAP Plugin (type=%d)", type];
            break;
    }

cleanup:
    if (ldapUser != nil)
        [ldapUser release];

    if (ldap != nil)
        [ldap release];

    if (pool != nil)
        [pool release];

    return (ret);
}
