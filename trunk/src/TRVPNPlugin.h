/*
 * TRVPNPlugin.h vi:ts=4:sw=4:expandtab:
 * Base Include File
 *
 * Author: Landon Fuller <landonf@threerings.net>
 *
 * Copyright (c) 2007 Landon Fuller <landonf@threerings.net>
 * Copyright (c) 2006 - 2007 Three Rings Design, Inc.
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
 * 3. Neither the name of the copyright holder nor the names of any contributors
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

#ifndef TRVPNPLUGIN_H
#define TRVPNPLUGIN_H

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "TRObject.h"
#include "TRLog.h"

#include "util/TRString.h"
#include "util/TREnumerator.h"
#include "util/TRArray.h"
#include "util/TRAutoreleasePool.h"
#include "util/TRHash.h"
#include "util/xmalloc.h"

#include "TRAccountRepository.h"
#include "TRVPNSession.h"

#include "config/TRConfigToken.h"
#include "config/TRConfig.h"
#include "config/TRConfigParser.h"
#include "config/TRAuthLDAPConfig.h"
#include "config/TRConfigLexer.h"
#include "config/TRLDAPGroupConfig.h"

#include "ldap/TRLDAPConnection.h"
#include "ldap/TRLDAPEntry.h"
#include "ldap/TRLDAPSearchFilter.h"
#include "ldap/TRLDAPAccountRepository.h"

#include "pf/TRPFAddress.h"
#include "pf/TRPacketFilter.h"
#include "pf/TRLocalPacketFilter.h"

#endif /* TRVPNPLUGIN_H */
