/*
 * tests.h
 * OpenVPN LDAP Authentication Plugin Unit Tests
 *
 * Author: Landon Fuller <landonf@threerings.net>
 *
 * Copyright (c) 2006 Three Rings Design, Inc.
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

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

/*
 * Useful Paths
 */
#define DATA_PATH(relative)	TEST_DATA "/" relative

#ifndef HAVE_PF
#define AUTH_LDAP_CONF		DATA_PATH("auth-ldap.conf")
#else
#define AUTH_LDAP_CONF		DATA_PATH("auth-ldap-pf.conf")
#endif /* HAVE_PF */

#define AUTH_LDAP_CONF_NAMED	DATA_PATH("auth-ldap-named.conf")
#define AUTH_LDAP_CONF_MISMATCHED	DATA_PATH("auth-ldap-mismatched.conf")
#define AUTH_LDAP_CONF_MULTIKEY	DATA_PATH("auth-ldap-multikey.conf")
#define AUTH_LDAP_CONF_REQUIRED DATA_PATH("auth-ldap-required.conf")

/*
 * Unit Tests
 */

Suite *LFString_suite(void);
Suite *LFAuthLDAPConfig_suite(void);
Suite *LFLDAPConnection_suite(void);
Suite *TRLDAPEntry_suite(void);
Suite *TRObject_suite(void);
Suite *TRArray_suite(void);
Suite *TRHash_suite(void);
Suite *TRConfigToken_suite(void);
Suite *TRConfigLexer_suite(void);
Suite *TRConfig_suite(void);
Suite *TRLDAPGroupConfig_suite(void);
Suite *TRPacketFilter_suite(void);
Suite *TRPFAddress_suite(void);
