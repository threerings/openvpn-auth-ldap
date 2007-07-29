/*
 * Main.java vi:ts=4:sw=4:expandtab:
 *
 * Copyright (c) 2007 Landon Fuller <landonf@threerings.net>
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

package com.threerings.authldap.test.ldapd;

import java.io.File;
import java.io.IOException;
import java.util.HashSet;
import java.util.Set;

import javax.naming.NamingException;
import javax.naming.directory.Attribute;
import javax.naming.directory.Attributes;
import javax.naming.directory.BasicAttribute;
import javax.naming.directory.BasicAttributes;

import org.apache.commons.io.FileUtils;
import org.apache.directory.server.configuration.MutableServerStartupConfiguration;
import org.apache.directory.server.core.configuration.MutablePartitionConfiguration;
import org.apache.mina.util.AvailablePortFinder;

/**
 * Manages an LDAP server for automated testing
 */
public class LDAPServer {
    public static void usage () {
        System.out.println("Usage: ldapd <data directory> <ldif file>");
    }

    public static void main (final String[] args) {
        if (args.length < 2) {
            usage();
            Runtime.getRuntime().exit(1);
        }

        final File dataDir = new File(args[0]);
        final File ldif = new File(args[1]);

        try {
            final LDAPServer server = new LDAPServer(dataDir, ldif);

        } catch (final IOException e) {
            System.err.println("IO error instantiating server: " + e.getMessage());
            Runtime.getRuntime().exit(1);

        } catch (final NamingException e) {
            System.err.println("LDAP instantiation error: " + e.getMessage());
            Runtime.getRuntime().exit(1);

        }
    }

    /**
     * Construct a new LDAP Server instance.
     * @throws IOException
     * @throws NamingException
     */
    public LDAPServer (final File dataDir, final File ldif)
        throws IOException, NamingException
    {
        /* Clean out the data directory */
        if (dataDir.exists()) {
            FileUtils.deleteDirectory(dataDir);
            if (dataDir.exists())
                throw new IOException("Unable to delete " + dataDir);
        }

        /* Find an available TCP port */
        final int port = AvailablePortFinder.getNextAvailable(1024);

        /* Configure the LDAP daemon */
        _config = new MutableServerStartupConfiguration();
        _config.setWorkingDirectory(dataDir);
        _config.setEnableNetworking(true);
        _config.setLdapPort(port);
        _config.setShutdownHookEnabled(false);

        /* Set up a test partition */
        final MutablePartitionConfiguration pcfg = new MutablePartitionConfiguration();
        pcfg.setName("test");
        pcfg.setSuffix(BASEDN);

        // Partition indices
        final Set<String> indices = new HashSet<String>();
        indices.add("objectClass");
        pcfg.setIndexedAttributes(indices);

        // Create the partition's base entry (o=test)
        final Attributes attrs = new BasicAttributes(true);
        Attribute attr;

        // objectClass attribute
        attr = new BasicAttribute("objectClass");
        attr.add("top");
        attr.add("o");
        attrs.put(attr);

        // organization attribute
        attr = new BasicAttribute("o");
        attr.add("test");
        attrs.put(attr);

        // Set the partition root entry
        pcfg.setContextEntry(attrs);

        /* Add the partition to our configuration */
        final Set<MutablePartitionConfiguration> pcfgs = new HashSet<MutablePartitionConfiguration>();
        pcfgs.add(pcfg);
        _config.setContextPartitionConfigurations(pcfgs);
    }

    /** Return the test partition base DN */
    public String getBaseDN () {
        return BASEDN;
    }

    private static final String BASEDN = "o=test";

    /** LDAP server configuration */
    private final MutableServerStartupConfiguration _config;
}